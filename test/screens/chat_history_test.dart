import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:top_places/app.dart';
import 'package:top_places/models/chat_message.dart';
import 'package:top_places/models/profile.dart';
import 'package:top_places/screens/chat_screen.dart';
import 'package:top_places/services/gemini_service.dart';
import 'package:top_places/services/places_repository.dart';
import 'package:top_places/view_models/account_view_model.dart';

import '../fake_account_service.dart';
import '../fake_chat_history_service.dart';
import '../fake_gemini.dart';

void main() {
  final repository = PlacesRepository.fromJsonStrings(
    placesJson: File('assets/data/locations.json').readAsStringSync(),
    citiesJson: File('assets/data/romanian_cities.json').readAsStringSync(),
  );
  const ana = Profile(
    id: 'ana',
    email: 'ana@test.ro',
    firstName: 'Ana',
    lastName: 'Pop',
    role: Role.user,
  );

  late FakeChatHistoryService chats;
  setUp(() => chats = FakeChatHistoryService());

  /// Two conversations from before: Pizza, then Cafea, the newest.
  void savedBefore() {
    final drago = repository.placeById('pizzeria-il-drago')!;
    chats
      ..savedBefore('Pizza în Brașov', [
        const ChatMessage.user('Unde găsesc pizza bună în Brașov?'),
        ChatMessage.bot(
          "Am găsit „Pizzeria 'Il Drago'”.",
          action: ShowPlace(drago),
        ),
      ])
      ..savedBefore('Cafea în Cluj', const [
        ChatMessage.user('Vreau să beau ceva în Cluj-Napoca'),
        ChatMessage.bot('În Cluj-Napoca poți bea ceva la: Coffee Shop Zen.'),
      ]);
  }

  /// Starts the app, signed in as Ana unless [signedIn] says otherwise,
  /// and opens the Asistent tab.
  Future<void> openChat(
    WidgetTester tester, {
    Profile? signedIn = ana,
    GeminiService? gemini,
    Size size = const Size(400, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      TopPlacesApp(
        repository: repository,
        gemini: gemini,
        accounts: FakeAccountService(signedIn: signedIn),
        chats: chats,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Asistent'));
    await tester.pumpAndSettle();
  }

  Future<void> send(WidgetTester tester, String message) async {
    await tester.enterText(find.byType(TextField), message);
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
  }

  Future<void> openHistory(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Conversații'));
    await tester.pumpAndSettle();
  }

  /// The title in the bar of the chat.
  Finder barTitle(String title) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(title));

  testWidgets(
    'a conversation is saved as it goes, titled by its first message',
    (tester) async {
      await openChat(tester);
      await send(tester, 'Vreau să beau ceva în Cluj-Napoca');
      await send(tester, 'Cum fac o rezervare?');

      final conversation = chats.saved.single;
      expect(conversation.title, 'Vreau să beau ceva în Cluj-Napoca');
      expect(
        [for (final row in chats.rows[conversation.id]!) row['author']],
        ['user', 'bot', 'user', 'bot'],
      );
      expect(chats.rows[conversation.id]![1]['city'], 'Cluj-Napoca');
      expect(barTitle('Vreau să beau ceva în Cluj-Napoca'), findsOneWidget);
    },
  );

  testWidgets(
    'the history lists the conversations, newest first, and opens one',
    (tester) async {
      savedBefore();
      await openChat(tester);
      await openHistory(tester);

      expect(
        tester.getTopLeft(find.text('Cafea în Cluj')).dy,
        lessThan(tester.getTopLeft(find.text('Pizza în Brașov')).dy),
      );
      await tester.tap(find.text('Pizza în Brașov'));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsNothing);
      expect(barTitle('Pizza în Brașov'), findsOneWidget);
      expect(find.text('Unde găsesc pizza bună în Brașov?'), findsOneWidget);
      // The button under the answer is back, with its place.
      expect(find.text('Arată pe hartă'), findsOneWidget);

      // A new message continues it, and brings it to the top.
      await send(tester, 'Cum fac o rezervare?');
      expect(chats.rows[chats.saved.first.id], hasLength(4));
      expect(chats.titles, ['Pizza în Brașov', 'Cafea în Cluj']);
    },
  );

  testWidgets('a new chat starts empty, and is saved apart', (tester) async {
    savedBefore();
    await openChat(tester);
    await openHistory(tester);
    await tester.tap(find.text('Cafea în Cluj'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Conversație nouă'));
    await tester.pumpAndSettle();

    expect(barTitle('Asistent'), findsOneWidget);
    expect(
      find.text('În Cluj-Napoca poți bea ceva la: Coffee Shop Zen.'),
      findsNothing,
    );
    // The suggestions of an empty chat are back.
    expect(find.byType(ActionChip), findsNWidgets(4));
    await send(tester, 'Cum fac o rezervare?');
    expect(chats.titles, [
      'Cum fac o rezervare?',
      'Cafea în Cluj',
      'Pizza în Brașov',
    ]);
  });

  testWidgets('any conversation can be renamed', (tester) async {
    savedBefore();
    await openChat(tester);
    await openHistory(tester);

    await tester.tap(find.byTooltip('Opțiuni pentru conversație').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redenumește'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      ),
      '  Pizza cu gașca ',
    );
    await tester.tap(find.text('Salvează'));
    await tester.pumpAndSettle();

    expect(chats.titles, ['Cafea în Cluj', 'Pizza cu gașca']);
    expect(find.text('Pizza cu gașca'), findsOneWidget);
  });

  testWidgets('a title cannot be left empty', (tester) async {
    savedBefore();
    await openChat(tester);
    await openHistory(tester);

    await tester.tap(find.byTooltip('Opțiuni pentru conversație').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Redenumește'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Salvează'));
    await tester.pumpAndSettle();

    expect(find.text('Câmp obligatoriu.'), findsOneWidget);
    expect(chats.titles, ['Cafea în Cluj', 'Pizza în Brașov']);
  });

  testWidgets(
    'deleting the open conversation, after asking, starts a new chat',
    (tester) async {
      savedBefore();
      await openChat(tester);
      await openHistory(tester);
      await tester.tap(find.text('Cafea în Cluj'));
      await tester.pumpAndSettle();
      await openHistory(tester);

      await tester.tap(find.byTooltip('Opțiuni pentru conversație').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Șterge'));
      await tester.pumpAndSettle();
      expect(
        find.text('„Cafea în Cluj” dispare, cu toate mesajele ei.'),
        findsOne,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Șterge'));
      await tester.pumpAndSettle();

      expect(chats.titles, ['Pizza în Brașov']);
      expect(find.text('Cafea în Cluj'), findsNothing);
      // Back in the chat: a new one.
      await tester.tapAt(const Offset(390, 450));
      await tester.pumpAndSettle();
      expect(barTitle('Asistent'), findsOneWidget);
      expect(
        find.text('În Cluj-Napoca poți bea ceva la: Coffee Shop Zen.'),
        findsNothing,
      );
    },
  );

  testWidgets('visitors who are not signed in chat without a history', (
    tester,
  ) async {
    await openChat(tester, signedIn: null);
    await send(tester, 'Cum fac o rezervare?');
    await openHistory(tester);

    expect(chats.saved, isEmpty);
    expect(
      find.text(
        'Intră în cont ca să-ți păstrezi conversațiile cu asistentul, '
        'pe orice dispozitiv.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, 'Intră în cont'));
    await tester.pumpAndSettle();
    final router = GoRouter.of(
      tester.element(find.byType(ChatScreen, skipOffstage: false)),
    );
    expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
  });

  testWidgets('signing out starts the chat afresh', (tester) async {
    await openChat(tester);
    await send(tester, 'Cum fac o rezervare?');

    await tester
        .element(find.byType(ChatScreen))
        .read<AccountViewModel>()
        .signOut();
    await tester.pumpAndSettle();

    expect(find.textContaining('WhatsApp'), findsNothing);
    expect(barTitle('Asistent'), findsOneWidget);
  });

  testWidgets('Gemini reads the conversation so far', (tester) async {
    savedBefore();
    final asked = <String>[];
    await openChat(
      tester,
      gemini: fakeGemini(
        "Încearcă prăjiturile de la Café 'New World', din Iași.",
        onRequest: (request) => asked.add(request.body),
      ),
    );
    await openHistory(tester);
    await tester.tap(find.text('Pizza în Brașov'));
    await tester.pumpAndSettle();

    await send(tester, 'Și ceva dulce după?');

    final contents = (jsonDecode(asked.single) as Map)['contents'] as List;
    expect(
      [for (final turn in contents) (turn as Map)['role']],
      ['user', 'model', 'user'],
    );
    expect(jsonEncode(contents.first), contains('pizza bună în Brașov'));
    // Saved with the rest, as Gemini's answer.
    expect(chats.rows[chats.saved.first.id]!.last['author'], 'ai');
  });

  testWidgets('when saving fails, the chat goes on and says so', (
    tester,
  ) async {
    await openChat(tester);
    chats.offline = true;
    await send(tester, 'Cum fac o rezervare?');

    expect(find.textContaining('WhatsApp'), findsOneWidget);
    expect(
      find.text(
        'Mesajele nu s-au putut salva în istoric. Verifică internetul.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a conversation that cannot be opened leaves a new chat', (
    tester,
  ) async {
    savedBefore();
    await openChat(tester);
    await openHistory(tester);
    chats.offline = true;
    await tester.tap(find.text('Pizza în Brașov'));
    await tester.pumpAndSettle();

    expect(
      find.text('Conversația nu s-a putut deschide. Verifică internetul.'),
      findsOneWidget,
    );
    expect(barTitle('Asistent'), findsOneWidget);
  });

  testWidgets('on a wide window the history is next to the chat', (
    tester,
  ) async {
    savedBefore();
    await openChat(tester, size: const Size(1200, 800));

    expect(find.byTooltip('Conversații'), findsNothing);
    await tester.tap(find.text('Pizza în Brașov'));
    await tester.pumpAndSettle();
    expect(find.text('Unde găsesc pizza bună în Brașov?'), findsOneWidget);
  });
}
