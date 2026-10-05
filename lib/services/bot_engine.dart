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

/// Words in a message that ask for a kind of place.
const _askedKinds = {
  _Kind.drink: ['bar', 'baruri', 'cafenea', 'cafenele', 'ceainarie', 'pub'],
  _Kind.food: ['restaurant', 'restaurante', 'pizzerie', 'trattoria', 'bistro'],
};

/// Verbs that say what someone wants to do: "să beau", "să mănânc".
const _verbs = {
  _Kind.drink: ['bea', 'beau', 'bei', 'bem'],
  _Kind.food: ['manca', 'mananc', 'mananci', 'mancam'],
};

/// What people ask for: a label for the answer, and the words that mean it
/// in a message (Romanian or English) or in the data (English).
const _items = [
  (label: 'cafea', words: ['cafea', 'cafe', 'coffee', 'espresso', 'latte']),
  (label: 'ceai', words: ['ceai', 'tea']),
  (label: 'matcha', words: ['matcha']),
  (label: 'pizza', words: ['pizza', 'pizzerie', 'pizzeria']),
  (label: 'burgeri', words: ['burger', 'burgeri', 'burgers']),
  (label: 'bere', words: ['bere', 'beer', 'pub']),
  (label: 'vin', words: ['vin', 'wine', 'wines']),
  (label: 'mâncare vegană', words: ['vegan', 'plant based']),
  (label: 'smoothie', words: ['smoothie', 'smoothies', 'sucuri', 'juices']),
  (label: 'paste', words: ['paste', 'pasta']),
  (label: 'sushi', words: ['sushi']),
];

const _best = ['cel mai bun', 'cea mai buna', 'cei mai buni', 'cele mai bune'];
const _worst = ['cel mai slab', 'cea mai slaba', 'cel mai prost'];

/// Short or English names that people use for two of the cities.
const _cityNicknames = {'cluj': 'Cluj-Napoca', 'bucharest': 'București'};

/// Short answers about the app, for messages that ask for no place. The
/// greeting comes last, so "Salut, cum rezerv?" gets the useful answer.
final _faq = [
  (
    RegExp(r'\brecomand'),
    'Pentru a găsi localuri, folosește pagina „Explorează”. Poți căuta după '
        'nume sau oraș, iar filtrele sortează după rating.',
  ),
  (
    RegExp(r'\brezerv'),
    'Poți face o rezervare din pagina unui local, cu butonul '
        '„Rezervă pe WhatsApp”.',
  ),
  (
    RegExp(r'\b(harta|lista)\b'),
    'Pe telefon, butonul de lângă căutare comută între listă și hartă. Pe un '
        'ecran lat le vezi pe amândouă.',
  ),
  (
    RegExp(r'\b(salut|buna|hello|hei)\b'),
    'Salut! Cu ce te pot ajuta astăzi? Poți să mă întrebi despre localuri '
        'sau despre cum funcționează aplicația.',
  ),
];

/// The assistant's rules, ported from getBotResponse in the old app. Plain
/// Dart without Flutter, so the tests run in milliseconds.
///
/// Messages are compared without diacritics and word by word: "Brașov"
/// matches "brasov", but "vin" no longer matches inside "servings".
class BotEngine {
  BotEngine({required this.places, required this.cities});

  /// The answer when no rule matches. The chat then asks Gemini, if it can.
  static const notUnderstood = ChatMessage.bot(
    'Nu am înțeles întrebarea. Poți reformula, te rog? Pot răspunde la '
    'întrebări despre localuri, rezervări sau funcțiile aplicației.',
  );

  final List<Place> places;
  final List<City> cities;

  /// Set after asking "În ce oraș…?", so that an answer with only a city
  /// continues the conversation. The old app forgot the question.
  _Kind? _waitingForCity;

  ChatMessage reply(String message) {
    final text = _plain(message);
    final city = _findCity(text);
    final item = _items.where((item) => _hasAny(text, item.words)).firstOrNull;
    final waitingFor = _waitingForCity;
    _waitingForCity = null;

    // 1. "Vreau să beau ceva în Iași": the places of that kind in the city.
    final wanted = _kindIn(text, _verbs) ?? (city != null ? waitingFor : null);
    if (wanted != null && item == null) {
      if (city == null) {
        _waitingForCity = wanted;
        final what = wanted == _Kind.drink ? 'bei ceva' : 'mănânci';
        return ChatMessage.bot('Sigur! În ce oraș ai vrea să $what?');
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
          'Am găsit „${place.name}”.',
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
      criteria.add(kind == _Kind.drink ? 'baruri/cafenele' : 'restaurante');
    }
    if (city != null) {
      found = found.where((place) => place.city == city).toList();
      criteria.add('din $city');
    }
    if (item != null) {
      found = found
          .where((place) => _hasAny(_textOf(place), item.words))
          .toList();
      criteria.add('care servește ${item.label}');
    }
    if (best || worst) {
      criteria.add(best ? 'cu cel mai bun rating' : 'cu cel mai slab rating');
    }
    if (criteria.isNotEmpty) {
      final list = criteria.join(', ');
      if (found.isEmpty) {
        return ChatMessage.bot(
          'Din păcate, nu am găsit niciun local care să corespundă '
          'criteriilor tale: $list.',
        );
      }
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
        'Am găsit „${place.name}”. Pare a fi ce căutai ($list).',
        action: ShowPlace(place),
      );
    }
    if (name != null) {
      return ChatMessage.bot(
        'Nu am găsit niciun local care să corespundă căutării „$name”.',
      );
    }

    // 4. Questions about the app.
    for (final (pattern, answer) in _faq) {
      if (pattern.hasMatch(text)) return ChatMessage.bot(answer);
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
      final what = switch (kind) {
        _Kind.drink => 'baruri sau cafenele',
        _Kind.food => 'restaurante',
        null => 'localuri',
      };
      return ChatMessage.bot('Din păcate, nu am găsit $what în $city.');
    }
    final intro = switch (kind) {
      _Kind.drink => 'poți bea ceva la',
      _Kind.food => 'poți mânca la',
      null => 'am găsit',
    };
    final names = found.map((place) => place.name).join(', ');
    return ChatMessage.bot('În $city $intro: $names.', action: ShowCity(city));
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

/// The name after "caută", "găsește", "vreau" or "arată-mi", without
/// "restaurantul" before it and "în" with a city after it.
String? _searchedName(String text) {
  final match = RegExp(
    r'\b(?:cauta|gaseste|vreau|arata mi)\s+(?:restaurantul\s+)?(.+)',
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
