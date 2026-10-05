import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:top_places/services/gemini_service.dart';

/// What the Gemini API sends back, with [text] as the answer.
http.Response geminiAnswer(String text) => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    }),
  ),
  200,
);

/// A GeminiService that never goes online: every question gets [text].
/// [onRequest] sees each request, for the tests that check what was asked.
GeminiService fakeGemini(
  String text, {
  void Function(http.Request request)? onRequest,
}) => GeminiService(
  apiKey: 'test-key',
  client: MockClient((request) async {
    onRequest?.call(request);
    return geminiAnswer(text);
  }),
);

/// Like [fakeGemini], with the next of [answers] for each request.
GeminiService fakeGeminiAnswers(
  List<String> answers, {
  void Function(http.Request request)? onRequest,
}) {
  var next = 0;
  return GeminiService(
    apiKey: 'test-key',
    client: MockClient((request) async {
      onRequest?.call(request);
      return geminiAnswer(answers[next++]);
    }),
  );
}
