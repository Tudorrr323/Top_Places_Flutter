import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:top_places/l10n/l10n.dart';
import 'package:top_places/models/conversation.dart';
import 'package:top_places/view_models/conversations_view_model.dart';
import 'package:top_places/widgets/dialogs.dart';

enum _Action { rename, delete }

/// The history of the chat: a button for a new conversation, then the
/// account's conversations, newest first, each with a menu to rename or
/// delete it. In a drawer on phones, next to the chat on wide windows.
class ConversationList extends StatelessWidget {
  const ConversationList({
    super.key,
    required this.currentId,
    required this.onNew,
    required this.onOpen,
    required this.onDeleted,
  });

  /// The conversation on screen, marked in the list; null for a new one.
  final String? currentId;

  final VoidCallback onNew;
  final ValueChanged<Conversation> onOpen;

  /// After a conversation is deleted, so that the chat leaves it if it was
  /// on screen.
  final ValueChanged<Conversation> onDeleted;

  /// Closes the drawer, if the list is in one.
  void _close(BuildContext context) => Scaffold.maybeOf(context)?.closeDrawer();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final chats = context.watch<ConversationsViewModel>();

    final Widget body;
    if (!chats.isAvailable) {
      body = _Note(
        text: l10n.chatHistorySignIn,
        action: l10n.signIn,
        onPressed: () {
          _close(context);
          context.go('/profile');
        },
      );
    } else if (chats.hasFailed) {
      body = _Note(
        text: l10n.chatHistoryNotLoaded,
        action: l10n.tryAgain,
        onPressed: chats.load,
      );
    } else if (chats.conversations.isEmpty) {
      body = chats.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _Note(text: l10n.chatHistoryEmpty);
    } else {
      body = ListView.builder(
        itemCount: chats.conversations.length,
        itemBuilder: (context, index) {
          final conversation = chats.conversations[index];
          return ListTile(
            selected: conversation.id == currentId,
            title: Text(
              conversation.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_when(l10n, conversation.updatedAt)),
            onTap: () {
              _close(context);
              onOpen(conversation);
            },
            trailing: PopupMenuButton<_Action>(
              tooltip: l10n.chatConversationActions,
              onSelected: (action) => switch (action) {
                _Action.rename => _rename(context, conversation),
                _Action.delete => _delete(context, conversation),
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _Action.rename,
                  child: ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(l10n.chatRename),
                  ),
                ),
                PopupMenuItem(
                  value: _Action.delete,
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline),
                    title: Text(l10n.delete),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.tonalIcon(
            onPressed: () {
              _close(context);
              onNew();
            },
            icon: const Icon(Icons.add_comment_outlined),
            label: Text(l10n.chatNew),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  /// The hour for today's conversations, the date for older ones.
  String _when(AppLocalizations l10n, DateTime time) =>
      DateUtils.isSameDay(time, DateTime.now())
      ? DateFormat.Hm(l10n.localeName).format(time)
      : l10n.date(time);

  Future<void> _rename(BuildContext context, Conversation conversation) async {
    final chats = context.read<ConversationsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final title = await askTitle(context, title: conversation.title);
    if (title == null || title == conversation.title) return;
    if (!await chats.rename(conversation, title)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatNotChanged)));
    }
  }

  Future<void> _delete(BuildContext context, Conversation conversation) async {
    final chats = context.read<ConversationsViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final confirmed = await askConfirmation(
      context,
      title: l10n.chatDeleteTitle,
      message: l10n.chatDeleteMessage(conversation.title),
      action: l10n.delete,
    );
    if (!confirmed) return;
    if (await chats.delete(conversation)) {
      onDeleted(conversation);
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.chatNotChanged)));
    }
  }
}

/// A short text in place of the list, with a button when there is
/// something to do.
class _Note extends StatelessWidget {
  const _Note({required this.text, this.action, this.onPressed});

  final String text;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onPressed, child: Text(action)),
          ],
        ],
      ),
    );
  }
}
