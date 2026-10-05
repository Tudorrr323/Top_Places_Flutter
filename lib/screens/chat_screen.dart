import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/models/conversation.dart';
import 'package:top_places/models/place.dart';
import 'package:top_places/services/bot_engine.dart';
import 'package:top_places/services/chat_history_service.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/utils/text_normalize.dart';
import 'package:top_places/view_models/conversations_view_model.dart';
import 'package:top_places/view_models/explore_view_model.dart';
import 'package:top_places/widgets/conversation_list.dart';

/// The Asistent tab: a chat with the assistant. Its rules answer at once;
/// what they don't understand goes to Gemini, when the app has a key.
/// Being a tab, it keeps the conversation while you look at the map.
///
/// A signed-in account keeps its conversations: each is saved as it goes,
/// and the history (a drawer on phones, a panel on wide windows) opens,
/// renames and deletes them.
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

  /// The conversation on screen, and its saving.
  var _session = _Session();

  /// True while a conversation from the history loads.
  bool _opening = false;

  /// The account whose conversation is on screen. When another one signs
  /// in, or this one signs out, the chat starts afresh.
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _gemini = context.read<GeminiService?>();
    _accountId = context.read<ConversationsViewModel>().accountId;
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  /// A new, empty conversation. The rules forget a question too.
  void _clear() {
    _session = _Session();
    _messages.clear();
    _waiting = false;
    _opening = false;
    _bot = null;
  }

  void _newChat() => setState(_clear);

  /// Opens a conversation from the history.
  Future<void> _open(Conversation conversation) async {
    if (conversation.id == _session.conversation?.id) return;
    final chats = context.read<ConversationsViewModel>();
    final repository = context.read<PlacesRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final session = _Session(conversation);
    setState(() {
      _clear();
      _session = session;
      _opening = true;
    });
    try {
      final messages = await chats.messagesOf(
        conversation,
        placeById: repository.placeById,
      );
      // Another conversation was chosen meanwhile.
      if (!mounted || session != _session) return;
      setState(() {
        _messages.addAll(messages);
        _opening = false;
      });
    } on ChatHistoryException {
      if (!mounted || session != _session) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatNotOpened)));
      setState(_clear);
    }
  }

  /// Leaves a deleted conversation, if it is on screen.
  void _deleted(Conversation conversation) {
    if (conversation.id == _session.conversation?.id) setState(_clear);
  }

  /// Saves [messages] in the session's conversation, starting it with the
  /// first one. Each save waits for the one before, so that a conversation
  /// is started only once and its messages stay in order. Only for a
  /// signed-in account.
  void _save(_Session session, List<ChatMessage> messages) {
    final chats = context.read<ConversationsViewModel>();
    if (!chats.isAvailable) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    session.saved = session.saved.then((_) async {
      try {
        final conversation = session.conversation ??= await chats.start(
          messages.first.text,
        );
        await chats.add(conversation, messages);
      } on ChatHistoryException {
        messenger.showSnackBar(SnackBar(content: Text(l10n.chatNotSaved)));
      }
    });
  }

  Future<void> _send(String text) async {
    final message = text.trim();
    if (message.isEmpty || _waiting || _opening) return;
    final bot = _bot!;
    final l10n = context.l10n;
    final session = _session;
    // Gemini reads the last messages too, so that a question can follow
    // the ones before it.
    final history = _messages.sublist(
      max(0, _messages.length - _historyForGemini),
    );
    // The rules speak Romanian and English. With a key, a message in
    // another language goes to Gemini, which answers in it. Told in
    // English: from Romanian instructions, Gemini answered Italian, which
    // looks like Romanian, in Romanian.
    final otherLanguage =
        _gemini != null && !BotEngine.speaksLanguageOf(message);
    final reply = otherLanguage ? bot.notUnderstood : bot.reply(message);
    final gemini = reply == bot.notUnderstood ? _gemini : null;
    final question = ChatMessage.user(message);
    setState(() {
      _messages.add(question);
      // The rules answer at once; the old app waited 500 ms to look busy.
      if (gemini == null) _messages.add(reply);
      _waiting = gemini != null;
    });
    _input.clear();
    if (gemini == null) {
      _save(session, [question, reply]);
      return;
    }

    final answer = await _askGemini(
      gemini,
      message,
      l10n,
      history: history,
      instructions: _instructions(
        otherLanguage ? lookupAppLocalizations(const Locale('en')) : l10n,
      ),
    );
    if (!mounted) return;
    // Saved in its own conversation, even if another is on screen now.
    _save(session, [question, answer]);
    if (session != _session) return;
    setState(() {
      _messages.add(answer);
      _waiting = false;
    });
  }

  /// What Gemini is told before every question, in the language of [l10n]:
  /// its role, the rules, and every place in the app, so that it doesn't
  /// invent others.
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
            'România. Răspunzi pe scurt (cel mult 3 propoziții), fără '
            'Markdown.',
        'Recomanzi doar localuri din lista de mai jos și le scrii numele '
            'exact ca în listă. Nu inventa alte localuri, adrese sau prețuri.',
        'Dacă întrebarea nu are legătură cu localurile sau cu ieșitul în '
            'oraș, spui politicos că te ocupi doar de localurile din aplicație.',
        'Limba răspunsului: aceeași cu a întrebării utilizatorului (germană, '
            'franceză, spaniolă, italiană, maghiară etc.), chiar dacă aceste '
            'instrucțiuni și lista sunt în română. Atenție: italiana, spaniola '
            'și franceza seamănă cu româna, dar nu sunt română; unei întrebări '
            'în italiană îi răspunzi în italiană. Doar dacă întrebarea e în '
            'română sau limba nu se poate ști, răspunzi în română.',
        'Localurile:',
      ] else ...[
        'You are the assistant of the Top Places app, which recommends places '
            'in Romania. Answer briefly (at most 3 sentences), without '
            'Markdown.',
        'Recommend only places from the list below, and write their names '
            'exactly as in the list. Do not invent other places, addresses or '
            'prices.',
        'If the question is not about places or going out, say politely that '
            'you only help with the places in the app.',
        "Language of the answer: the same as the language of the user's "
            'question (German, French, Spanish, Italian, Hungarian and so '
            'on), even though these instructions and the list are in English. '
            'Italian, Spanish and French look like Romanian but are not '
            'Romanian; a question in Italian gets an answer in Italian. Only '
            'when the question is in English or its language cannot be told, '
            'answer in English.',
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
    AppLocalizations l10n, {
    required List<ChatMessage> history,
    required String instructions,
  }) async {
    try {
      final text = await gemini.generate(
        message,
        instructions: instructions,
        history: history,
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
    final chats = context.watch<ConversationsViewModel>();
    final l10n = context.l10n;
    if (chats.accountId != _accountId) {
      // Without setState: this build shows the empty chat.
      _accountId = chats.accountId;
      _clear();
    }
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

    final current = _session.conversation;
    // The list has the title as renamed.
    final title = current == null
        ? l10n.tabAssistant
        : chats.conversations
                  .where((conversation) => conversation.id == current.id)
                  .firstOrNull
                  ?.title ??
              current.title;
    final history = ConversationList(
      currentId: current?.id,
      onNew: _newChat,
      onOpen: _open,
      onDeleted: _deleted,
    );

    final chat = Center(
      // On wide windows the conversation stays readable instead of
      // stretching.
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _opening
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
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
            if (_messages.isEmpty && !_opening)
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
                    onPressed: _waiting || _opening
                        ? null
                        : () => _send(_input.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // The same width at which Explore shows the list next to the map.
        final wide = constraints.maxWidth >= 840;
        return Scaffold(
          appBar: AppBar(
            leading: wide
                ? null
                : Builder(
                    // Under the Scaffold, so that it finds its drawer.
                    builder: (context) => IconButton(
                      tooltip: l10n.chatHistory,
                      onPressed: Scaffold.of(context).openDrawer,
                      icon: const Icon(Icons.menu),
                    ),
                  ),
            title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: l10n.chatNew,
                onPressed: _newChat,
                icon: const Icon(Icons.add_comment_outlined),
              ),
            ],
          ),
          drawer: wide ? null : Drawer(child: SafeArea(child: history)),
          body: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: 300, child: history),
                    const VerticalDivider(width: 1),
                    Expanded(child: chat),
                  ],
                )
              : chat,
        );
      },
    );
  }
}

/// How many earlier messages Gemini reads with a question.
const _historyForGemini = 10;

/// One conversation on screen. [conversation] is null until the first
/// message is saved; [saved] completes when the last save is done.
class _Session {
  _Session([this.conversation]);

  Conversation? conversation;
  Future<void> saved = Future.value();
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
