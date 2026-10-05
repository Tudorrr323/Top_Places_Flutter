import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/services/bot_engine.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/utils/text_normalize.dart';
import 'package:top_places/view_models/explore_view_model.dart';

/// Questions to start with, shown until the first message is sent.
const _suggestions = [
  'Vreau să beau ceva în Cluj-Napoca',
  'Cea mai bună cafea',
  'Caută Burger Shack',
  'Cum fac o rezervare?',
];

/// The Asistent tab: a chat with the assistant. Its rules answer at once;
/// what they don't understand goes to Gemini, when the app has a key.
/// Being a tab, it keeps the conversation while you look at the map.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _messages = <ChatMessage>[];

  /// Made again when the places change (the live list from Supabase).
  late BotEngine _bot;

  /// Null when the app runs without a Gemini key.
  late final GeminiService? _gemini;

  /// True while Gemini writes an answer.
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    final repository = context.read<PlacesRepository>();
    _bot = BotEngine(places: repository.places, cities: repository.cities);
    _gemini = context.read<GeminiService?>();
    _messages.add(
      ChatMessage.bot(
        'Salut! Sunt asistentul Top Places. Răspund pe loc la întrebări '
        'despre localuri, orașe și rezervări'
        '${_gemini == null ? '.' : ', iar ce nu știu întreb AI-ul (Gemini).'}',
      ),
    );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final message = text.trim();
    if (message.isEmpty || _waiting) return;
    final reply = _bot.reply(message);
    final gemini = reply == BotEngine.notUnderstood ? _gemini : null;
    setState(() {
      _messages.add(ChatMessage.user(message));
      // The rules answer at once; the old app waited 500 ms to look busy.
      if (gemini == null) _messages.add(reply);
      _waiting = gemini != null;
    });
    _input.clear();
    if (gemini == null) return;

    final answer = await _askGemini(gemini, message);
    if (!mounted) return;
    setState(() {
      _messages.add(answer);
      _waiting = false;
    });
  }

  /// What Gemini is told before every question: its role, the rules, and
  /// every place in the app, so that it doesn't invent others.
  String get _instructions => [
    'Ești asistentul aplicației Top Places, care recomandă localuri din '
        'România. Răspunzi în română, pe scurt (cel mult 3 propoziții), '
        'fără Markdown.',
    'Recomanzi doar localuri din lista de mai jos și le scrii numele exact '
        'ca în listă. Nu inventa alte localuri, adrese sau prețuri.',
    'Dacă întrebarea nu are legătură cu localurile sau cu ieșitul în oraș, '
        'spui politicos că te ocupi doar de localurile din aplicație.',
    'Localurile:',
    for (final place in _bot.places)
      '- ${place.name}, ${place.city}, '
          '${place.isRated ? 'rating ${place.ratingText}' : 'local nou, '
                    'fără rating încă'}: '
          '${place.description}',
  ].join('\n');

  Future<ChatMessage> _askGemini(GeminiService gemini, String message) async {
    try {
      final text = await gemini.generate(message, instructions: _instructions);
      return ChatMessage.ai(text, action: _placeNamedIn(text));
    } on GeminiException catch (error) {
      return ChatMessage.bot(
        error.isQuotaExceeded
            ? 'Nu am înțeles întrebarea, iar AI-ul și-a atins limita gratuită '
                  'pentru moment. Întreabă-mă despre localuri, orașe sau '
                  'rezervări.'
            : 'Nu am înțeles întrebarea, iar AI-ul nu răspunde acum (poate '
                  'lipsește internetul). Întreabă-mă despre localuri, orașe '
                  'sau rezervări.',
      );
    }
  }

  /// "Arată pe hartă" for an answer from Gemini that names exactly one place.
  ChatAction? _placeNamedIn(String text) {
    final slug = slugify(text);
    final named = _bot.places
        .where((place) => slug.contains(slugify(place.name)))
        .toList();
    return named.length == 1 ? ShowPlace(named.single) : null;
  }

  void _showOnMap(ChatAction action) {
    context.read<ExploreViewModel>().showOnMap(action);
    // The result is on the Explore tab, so go there. The old app changed
    // Explore in the background, and from Profile nothing seemed to happen.
    context.go('/explore');
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<PlacesRepository>();
    if (!identical(repository.places, _bot.places)) {
      _bot = BotEngine(places: repository.places, cities: repository.cities);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Asistent')),
      body: Center(
        // On wide windows the conversation stays readable instead of
        // stretching.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView.builder(
                  // Built from the bottom up, so the newest message is
                  // always in view without scrolling.
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _Bubble(
                    message: _messages[_messages.length - 1 - index],
                    onShowOnMap: _showOnMap,
                  ),
                ),
              ),
              if (_messages.length == 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final suggestion in _suggestions)
                        ActionChip(
                          label: Text(suggestion),
                          onPressed: () => _send(suggestion),
                        ),
                    ],
                  ),
                ),
              if (_waiting)
                const LinearProgressIndicator(
                  semanticsLabel: 'Gemini scrie un răspuns',
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        decoration: const InputDecoration(
                          hintText: 'Scrie un mesaj...',
                          border: OutlineInputBorder(),
                        ),
                        // Enter sends, on a keyboard or on a phone.
                        textInputAction: TextInputAction.send,
                        onSubmitted: _send,
                        // Keeps the focus (and the phone keyboard) for the
                        // next message.
                        onEditingComplete: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Trimite',
                      onPressed: _waiting ? null : () => _send(_input.text),
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One message: the user's on the right, the assistant's on the left, with
/// a button when the answer has something to show on the map.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.onShowOnMap});

  final ChatMessage message;
  final ValueChanged<ChatAction> onShowOnMap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fromUser = message.fromUser;
    final action = message.action;

    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Card(
          color: fromUser ? colors.primary : colors.surfaceContainerHighest,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Screen readers say who wrote the message, and read the
                // assistant's answers as soon as they appear.
                Semantics(
                  label: fromUser ? 'Tu' : 'Asistentul',
                  liveRegion: !fromUser,
                  child: Text(
                    message.text,
                    style: TextStyle(
                      color: fromUser ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
                if (message.fromAi) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Generat cu Gemini. Poate conține greșeli.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
                if (action != null) ...[
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: () => onShowOnMap(action),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Arată pe hartă'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
