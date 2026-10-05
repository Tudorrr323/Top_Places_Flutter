import 'package:flutter_test/flutter_test.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/view_models/account_view_model.dart';
import 'package:top_places/view_models/conversations_view_model.dart';

import '../fake_account_service.dart';
import '../fake_chat_history_service.dart';

void main() {
  const ana = Profile(
    id: 'ana',
    email: 'ana@test.ro',
    firstName: 'Ana',
    lastName: 'Pop',
    role: Role.user,
  );

  late FakeChatHistoryService service;
  late FakeAccountService accounts;
  late AccountViewModel account;

  setUp(() {
    service = FakeChatHistoryService()
      ..savedBefore('Pizza', const [ChatMessage.user('Pizza')])
      ..savedBefore('Cafea', const [ChatMessage.user('Cafea')]);
    accounts = FakeAccountService(signedIn: ana);
    account = AccountViewModel(accounts);
  });

  test('without Supabase, or signed out, there is no history', () async {
    expect(ConversationsViewModel(null, account).isAvailable, isFalse);
    final visitor = AccountViewModel(FakeAccountService());
    await pumpEventQueue();
    expect(ConversationsViewModel(service, visitor).isAvailable, isFalse);
  });

  test("loads the account's conversations, newest first", () async {
    final chats = ConversationsViewModel(service, account);
    await pumpEventQueue();

    expect(chats.accountId, 'ana');
    expect([for (final c in chats.conversations) c.title], ['Cafea', 'Pizza']);
  });

  test('a new conversation and a new message go to the top', () async {
    final chats = ConversationsViewModel(service, account);
    await pumpEventQueue();

    final started = await chats.start('  Unde mănânc în Iași?  ');
    expect(chats.conversations.first.title, 'Unde mănânc în Iași?');

    final pizza = chats.conversations.last;
    await chats.add(pizza, const [ChatMessage.user('Și în Cluj?')]);
    expect(
      [for (final c in chats.conversations) c.title],
      ['Pizza', 'Unde mănânc în Iași?', 'Cafea'],
    );
    expect(service.rows[started.id], isEmpty);
    expect(service.rows[pizza.id], hasLength(2));
  });

  test('signing out forgets the conversations', () async {
    final chats = ConversationsViewModel(service, account);
    await pumpEventQueue();

    await account.signOut();

    expect(chats.isAvailable, isFalse);
    expect(chats.conversations, isEmpty);
  });

  test('renames and deletes, and says when it could not', () async {
    final chats = ConversationsViewModel(service, account);
    await pumpEventQueue();
    final cafea = chats.conversations.first;

    expect(await chats.rename(cafea, 'Cafele bune'), isTrue);
    expect(chats.conversations.first.title, 'Cafele bune');
    expect(await chats.delete(chats.conversations.first), isTrue);
    expect(service.titles, ['Pizza']);

    service.offline = true;
    expect(await chats.rename(chats.conversations.first, 'X'), isFalse);
    expect(await chats.delete(chats.conversations.first), isFalse);
    expect([for (final c in chats.conversations) c.title], ['Pizza']);
  });

  test('a list that could not load can be tried again', () async {
    service.offline = true;
    final chats = ConversationsViewModel(service, account);
    await pumpEventQueue();
    expect(chats.hasFailed, isTrue);

    service.offline = false;
    await chats.load();
    expect(chats.hasFailed, isFalse);
    expect(chats.conversations, hasLength(2));
  });
}
