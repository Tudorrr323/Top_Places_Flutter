import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:top_places/services/gemini_service.dart';

import '../fake_gemini.dart';

void main() {
  test('sends the key and the instructions, and returns the text', () async {
    late http.Request sent;
    final gemini = GeminiService(
      apiKey: 'test-key',
      client: MockClient((request) async {
        sent = request;
        return geminiAnswer('Un loc liniștit, cu cafea bună. ☕\n');
      }),
    );

    final text = await gemini.generate('Salut', instructions: 'Fii scurt.');

    expect(text, 'Un loc liniștit, cu cafea bună. ☕');
    expect(sent.headers['x-goog-api-key'], 'test-key');
    expect(sent.url.path, endsWith('gemini-3.5-flash-lite:generateContent'));
    expect(sent.body, contains('Fii scurt.'));
  });

  test('a 429 means the free limit is reached', () async {
    final gemini = GeminiService(
      apiKey: 'test-key',
      client: MockClient((request) async => http.Response('{}', 429)),
    );

    await expectLater(
      gemini.generate('Salut', instructions: ''),
      throwsA(
        isA<GeminiException>().having(
          (error) => error.isQuotaExceeded,
          'isQuotaExceeded',
          isTrue,
        ),
      ),
    );
  });

  test('an answer without text is an error', () async {
    final gemini = GeminiService(
      apiKey: 'test-key',
      client: MockClient((request) async => http.Response('{}', 200)),
    );

    await expectLater(
      gemini.generate('Salut', instructions: ''),
      throwsA(isA<GeminiException>()),
    );
  });

  test('no answer in time is an error', () async {
    final gemini = GeminiService(
      apiKey: 'test-key',
      timeout: const Duration(milliseconds: 10),
      client: MockClient((request) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return geminiAnswer('Prea târziu.');
      }),
    );

    await expectLater(
      gemini.generate('Salut', instructions: ''),
      throwsA(isA<GeminiException>()),
    );
  });
}
