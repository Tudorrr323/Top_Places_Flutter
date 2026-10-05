import 'package:top_places/l10n/app_localizations.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/models/city.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/utils/text_normalize.dart';

/// Where you go for a drink, and where you go to eat. A place can be both,
/// like a café that serves brunch.
enum _Kind { drink, food }

/// Words in the names and descriptions of the places (in English) that show
/// what they serve.
const _placeWords = {
  _Kind.drink: [
    'bar',
    'beer',
    'cafe',
    'coffee',
    'coffees',
    'espresso',
    'juices',
    'pub',
    'smoothie',
    'smoothies',
    'tea',
    'wines',
  ],
  _Kind.food: [
    'bakery',
    'bistro',
    'breakfast',
    'brunch',
    'burger',
    'burgers',
    'cakes',
    'dinner',
    'dishes',
    'fish',
    'food',
    'kebab',
    'lunch',
    'menu',
    'pasta',
    'pizza',
    'pizzeria',
    'restaurant',
    'seafood',
    'soups',
    'trattoria',
  ],
};

/// Words in a message (Romanian or English) that ask for a kind of place.
const _askedKinds = {
  _Kind.drink: [
    'bar',
    'baruri',
    'bars',
    'cafenea',
    'cafenele',
    'cafes',
    'ceainarie',
    'coffee shop',
    'coffee shops',
    'pub',
    'pubs',
  ],
  _Kind.food: [
    'bistro',
    'pizzerie',
    'restaurant',
    'restaurante',
    'restaurants',
    'trattoria',
  ],
};

/// Verbs that say what someone wants to do: "să beau", "to eat".
const _verbs = {
  _Kind.drink: ['bea', 'beau', 'bei', 'bem', 'drink'],
  _Kind.food: ['manca', 'mananc', 'mananci', 'mancam', 'eat'],
};

/// What people ask for: its name in the answer, and the words that mean it
/// in a message (Romanian or English) or in the data (English).
final _items = <(String Function(AppLocalizations), List<String>)>[
  (
    (l10n) => l10n.botItemCoffee,
    ['cafea', 'cafe', 'coffee', 'espresso', 'latte'],
  ),
  ((l10n) => l10n.botItemTea, ['ceai', 'tea']),
  ((l10n) => l10n.botItemMatcha, ['matcha']),
  ((l10n) => l10n.botItemPizza, ['pizza', 'pizzerie', 'pizzeria']),
  ((l10n) => l10n.botItemBurgers, ['burger', 'burgeri', 'burgers']),
  ((l10n) => l10n.botItemBeer, ['bere', 'beer', 'pub']),
  ((l10n) => l10n.botItemWine, ['vin', 'wine', 'wines']),
  ((l10n) => l10n.botItemVegan, ['vegan', 'plant based']),
  (
    (l10n) => l10n.botItemSmoothie,
    ['smoothie', 'smoothies', 'sucuri', 'juices'],
  ),
  ((l10n) => l10n.botItemPasta, ['paste', 'pasta']),
  ((l10n) => l10n.botItemSushi, ['sushi']),
];

const _best = [
  'cel mai bun',
  'cea mai buna',
  'cei mai buni',
  'cele mai bune',
  'best',
  'top',
];
const _worst = [
  'cel mai slab',
  'cea mai slaba',
  'cel mai prost',
  'worst',
  'lowest rated',
];

/// Short or English names that people use for two of the cities.
const _cityNicknames = {'cluj': 'Cluj-Napoca', 'bucharest': 'București'};

/// Short answers about the app, for messages that ask for no place. The
/// greeting comes last, so "Salut, cum rezerv?" gets the useful answer.
final _faq = <(RegExp, String Function(AppLocalizations))>[
  (RegExp(r'\b(recomand|recommend)'), (l10n) => l10n.botRecommend),
  (RegExp(r'\b(rezerv|reserv|book)'), (l10n) => l10n.botBooking),
  (RegExp(r'\b(harta|lista|map|list)\b'), (l10n) => l10n.botMapList),
  (RegExp(r'\b(salut|buna|hello|hei|hey|hi)\b'), (l10n) => l10n.botGreeting),
];

/// The assistant's rules, ported from getBotResponse in the old app. Plain
/// Dart without Flutter, so the tests run in milliseconds. It understands
/// Romanian and English, and answers in the language of [l10n].
///
/// Messages are compared without diacritics and word by word: "Brașov"
/// matches "brasov", but "vin" no longer matches inside "servings".
class BotEngine {
  BotEngine({required this.places, required this.cities, required this.l10n});

  final List<Place> places;
  final List<City> cities;

  /// The texts of the answers, in the language of the app.
  final AppLocalizations l10n;

  /// The answer when no rule matches. The chat then asks Gemini, if it can.
  late final notUnderstood = ChatMessage.bot(l10n.botNotUnderstood);

  /// Set after asking "În ce oraș…?", so that an answer with only a city
  /// continues the conversation. The old app forgot the question.
  _Kind? _waitingForCity;

  ChatMessage reply(String message) {
    final text = _plain(message);
    final city = _findCity(text);
    final item = _items.where((item) => _hasAny(text, item.$2)).firstOrNull;
    final waitingFor = _waitingForCity;
    _waitingForCity = null;

    // 1. "Vreau să beau ceva în Iași": the places of that kind in the city.
    final wanted = _kindIn(text, _verbs) ?? (city != null ? waitingFor : null);
    if (wanted != null && item == null) {
      if (city == null) {
        _waitingForCity = wanted;
        return ChatMessage.bot(
          wanted == _Kind.drink
              ? l10n.botWhichCityDrink
              : l10n.botWhichCityFood,
        );
      }
      return _placesIn(city, wanted);
    }

    // 2. "Caută New World": a place by its name.
    final name = _searchedName(text);
    if (name != null) {
      final place = places
          .where((place) => slugify(place.name).contains(slugify(name)))
          .firstOrNull;
      if (place != null) {
        return ChatMessage.bot(
          l10n.botFound(place.name),
          action: ShowPlace(place),
        );
      }
    }

    // 3. "Cea mai bună cafea din Cluj": filters and sorting.
    final kind = _kindIn(text, _askedKinds);
    final best = _hasAny(text, _best);
    final worst = !best && _hasAny(text, _worst);
    if (city != null && kind == null && item == null && !best && !worst) {
      return _placesIn(city, null);
    }
    var found = places;
    final criteria = <String>[];
    if (kind != null) {
      found = found.where((place) => _isKind(place, kind)).toList();
      criteria.add(
        kind == _Kind.drink ? l10n.botCriterionDrink : l10n.botCriterionFood,
      );
    }
    if (city != null) {
      found = found.where((place) => place.city == city).toList();
      criteria.add(l10n.botCriterionCity(city));
    }
    if (item case (final label, final words)) {
      found = found.where((place) => _hasAny(_textOf(place), words)).toList();
      criteria.add(l10n.botCriterionItem(label(l10n)));
    }
    if (best || worst) {
      criteria.add(best ? l10n.botCriterionBest : l10n.botCriterionWorst);
    }
    if (criteria.isNotEmpty) {
      final list = criteria.join(', ');
      if (found.isEmpty) return ChatMessage.bot(l10n.botNothingMatching(list));
      // The best and the worst are chosen among the rated places; a new
      // place has no rating to compare yet.
      final rated = found.where((place) => place.isRated).toList();
      final ranked = rated.isEmpty ? found : rated;
      // reduce() keeps the first of equal ratings, as the old sort did.
      final place = switch ((best, worst)) {
        (true, _) => ranked.reduce((a, b) => b.rating > a.rating ? b : a),
        (_, true) => ranked.reduce((a, b) => b.rating < a.rating ? b : a),
        _ => found.first,
      };
      return ChatMessage.bot(
        l10n.botFoundMatching(place.name, list),
        action: ShowPlace(place),
      );
    }
    if (name != null) return ChatMessage.bot(l10n.botNothingNamed(name));

    // 4. Questions about the app.
    for (final (pattern, answer) in _faq) {
      if (pattern.hasMatch(text)) return ChatMessage.bot(answer(l10n));
    }
    return notUnderstood;
  }

  /// The places of [kind] in [city] (of any kind if null), named in the
  /// answer, with a button that shows the city on the map.
  ChatMessage _placesIn(String city, _Kind? kind) {
    final found = places
        .where((place) => place.city == city)
        .where((place) => kind == null || _isKind(place, kind))
        .toList();
    if (found.isEmpty) {
      return ChatMessage.bot(switch (kind) {
        _Kind.drink => l10n.botNoDrinkIn(city),
        _Kind.food => l10n.botNoFoodIn(city),
        null => l10n.botNoPlacesIn(city),
      });
    }
    final names = found.map((place) => place.name).join(', ');
    return ChatMessage.bot(switch (kind) {
      _Kind.drink => l10n.botDrinkIn(city, names),
      _Kind.food => l10n.botFoodIn(city, names),
      null => l10n.botPlacesIn(city, names),
    }, action: ShowCity(city));
  }

  /// The city named in [text], or null.
  String? _findCity(String text) {
    for (final city in cities) {
      if (_hasWord(text, _plain(city.name))) return city.name;
    }
    for (final MapEntry(key: nickname, value: city) in _cityNicknames.entries) {
      if (_hasWord(text, nickname)) return city;
    }
    return null;
  }

  bool _isKind(Place place, _Kind kind) =>
      _hasAny(_textOf(place), _placeWords[kind]!);
}

/// Lower case, without diacritics and with hyphens as spaces, so that
/// "Cluj-Napoca", "cluj napoca" and "CLUJ-NAPOCA" are written the same.
String _plain(String text) => normalize(text).replaceAll('-', ' ');

String _textOf(Place place) => _plain('${place.name} ${place.description}');

/// The first kind whose words appear in [text], or null.
_Kind? _kindIn(String text, Map<_Kind, List<String>> words) {
  for (final MapEntry(key: kind, value: list) in words.entries) {
    if (_hasAny(text, list)) return kind;
  }
  return null;
}

/// The name after "caută", "găsește", "vreau", "arată-mi", "find", "search
/// for", "show me" or "look for", without "restaurantul" or "the" before it
/// and "în"/"in" with a city after it.
String? _searchedName(String text) {
  final match = RegExp(
    r'\b(?:cauta|gaseste|vreau|arata mi|find|search for|search|show me|look for)'
    r'\s+(?:restaurantul\s+|the\s+)?(.+)',
  ).firstMatch(text);
  final name = match?.group(1)?.replaceFirst(RegExp(r'\s+in\s.*$'), '').trim();
  return name == null || slugify(name).isEmpty ? null : name;
}

/// Whether [phrase] appears in [text] as whole words: "vin" is found in
/// "un vin bun", but not in "servings".
bool _hasWord(String text, String phrase) =>
    RegExp('\\b${RegExp.escape(phrase)}\\b').hasMatch(text);

bool _hasAny(String text, List<String> phrases) =>
    phrases.any((phrase) => _hasWord(text, phrase));
