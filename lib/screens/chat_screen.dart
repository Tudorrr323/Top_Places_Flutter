import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/services/bot_engine.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/view_models/explore_view_model.dart';

/// Questions to start with, shown until the first message is sent.
const _suggestions = [
  'Vreau să beau ceva în Cluj-Napoca',
  'Cea mai bună cafea',
  'Caută Burger Shack',
  'Cum fac o rezervare?',
];

/// The Asistent tab: a chat with the rule-based assistant. Being a tab, it
/// keeps the conversation while you look at the map.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _messages = [
    const ChatMessage.bot(
      'Salut! Sunt asistentul tău virtual. Cum te pot ajuta?',
    ),
  ];
  late final BotEngine _bot;

  @override
  void initState() {
    super.initState();
    final repository = context.read<PlacesRepository>();
    _bot = BotEngine(places: repository.places, cities: repository.cities);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage.user(text.trim()));
      // The answer comes at once; the old app waited 500 ms to look busy.
      _messages.add(_bot.reply(text));
    });
    _input.clear();
  }

  void _showOnMap(ChatAction action) {
    context.read<ExploreViewModel>().showOnMap(action);
    // The result is on the Explore tab, so go there. The old app changed
    // Explore in the background, and from Profile nothing seemed to happen.
    context.go('/explore');
  }

  @override
  Widget build(BuildContext context) {
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
                      onPressed: () => _send(_input.text),
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
    final colors = Theme.of(context).colorScheme;
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
