import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/bot_engine.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/utils/text_normalize.dart';
import 'package:top_places/view_models/explore_view_model.dart';

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

  /// The conversation, after the welcome, which follows the language.
  final _messages = <ChatMessage>[];

  /// Made again when the places change (the live list from Supabase), or
  /// the language.
  BotEngine? _bot;

  /// Null when the app runs without a Gemini key.
  late final GeminiService? _gemini;

  /// True while Gemini writes an answer.
  bool _waiting = false;

  @override
  void initState() {
    super.initState();
    _gemini = context.read<GeminiService?>();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final message = text.trim();
    if (message.isEmpty || _waiting) return;
    final bot = _bot!;
    final l10n = context.l10n;
    final reply = bot.reply(message);
    final gemini = reply == bot.notUnderstood ? _gemini : null;
    setState(() {
      _messages.add(ChatMessage.user(message));
      // The rules answer at once; the old app waited 500 ms to look busy.
      if (gemini == null) _messages.add(reply);
      _waiting = gemini != null;
    });
    _input.clear();
    if (gemini == null) return;

    final answer = await _askGemini(gemini, message, l10n);
    if (!mounted) return;
    setState(() {
      _messages.add(answer);
      _waiting = false;
    });
  }

  /// What Gemini is told before every question, in the language of the
  /// app: its role, the rules, and every place in the app, so that it
  /// doesn't invent others.
  String _instructions(AppLocalizations l10n) {
    final romanian = l10n.localeName == 'ro';
    String rating(Place place) => switch ((place.isRated, romanian)) {
      (true, true) => 'rating ${l10n.placeRating(place)}',
      (true, false) => 'rated ${l10n.placeRating(place)}',
      (false, true) => 'local nou, fără rating încă',
      (false, false) => 'a new place, not rated yet',
    };
    return [
      if (romanian) ...[
        'Ești asistentul aplicației Top Places, care recomandă localuri din '
            'România. Răspunzi în română, pe scurt (cel mult 3 propoziții), '
            'fără Markdown.',
        'Recomanzi doar localuri din lista de mai jos și le scrii numele '
            'exact ca în listă. Nu inventa alte localuri, adrese sau prețuri.',
        'Dacă întrebarea nu are legătură cu localurile sau cu ieșitul în '
            'oraș, spui politicos că te ocupi doar de localurile din aplicație.',
        'Localurile:',
      ] else ...[
        'You are the assistant of the Top Places app, which recommends places '
            'in Romania. Answer in English, briefly (at most 3 sentences), '
            'without Markdown.',
        'Recommend only places from the list below, and write their names '
            'exactly as in the list. Do not invent other places, addresses or '
            'prices.',
        'If the question is not about places or going out, say politely that '
            'you only help with the places in the app.',
        'The places:',
      ],
      for (final place in _bot!.places)
        '- ${place.name}, ${place.city}, ${rating(place)}: '
            '${l10n.description(place)}',
    ].join('\n');
  }

  Future<ChatMessage> _askGemini(
    GeminiService gemini,
    String message,
    AppLocalizations l10n,
  ) async {
    try {
      final text = await gemini.generate(
        message,
        instructions: _instructions(l10n),
      );
      return ChatMessage.ai(text, action: _placeNamedIn(text));
    } on GeminiException catch (error) {
      return ChatMessage.bot(
        error.isQuotaExceeded ? l10n.chatAiQuota : l10n.chatAiDown,
      );
    }
  }

  /// "Arată pe hartă" for an answer from Gemini that names exactly one place.
  ChatAction? _placeNamedIn(String text) {
    final slug = slugify(text);
    final named = _bot!.places
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
    final l10n = context.l10n;
    final bot = _bot;
    if (bot == null ||
        !identical(repository.places, bot.places) ||
        bot.l10n.localeName != l10n.localeName) {
      _bot = BotEngine(
        places: repository.places,
        cities: repository.cities,
        l10n: l10n,
      );
    }
    final welcome = ChatMessage.bot(
      _gemini == null ? l10n.chatWelcome : l10n.chatWelcomeWithAi,
    );
    final suggestions = [
      l10n.chatSuggestion1,
      l10n.chatSuggestion2,
      l10n.chatSuggestion3,
      l10n.chatSuggestion4,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabAssistant)),
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
                  itemCount: _messages.length + 1,
                  itemBuilder: (context, index) => _Bubble(
                    // The welcome first, at the top.
                    message: index == _messages.length
                        ? welcome
                        : _messages[_messages.length - 1 - index],
                    onShowOnMap: _showOnMap,
                  ),
                ),
              ),
              if (_messages.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final suggestion in suggestions)
                        ActionChip(
                          label: Text(suggestion),
                          onPressed: () => _send(suggestion),
                        ),
                    ],
                  ),
                ),
              if (_waiting)
                LinearProgressIndicator(semanticsLabel: l10n.chatGeminiWriting),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        decoration: InputDecoration(
                          hintText: l10n.chatHint,
                          border: const OutlineInputBorder(),
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
                      tooltip: l10n.chatSend,
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
                  label: fromUser
                      ? context.l10n.chatYou
                      : context.l10n.chatAssistant,
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
                    context.l10n.aiNote,
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
                    label: Text(context.l10n.showOnMap),
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
