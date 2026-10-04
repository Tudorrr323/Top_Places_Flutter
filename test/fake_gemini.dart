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
GeminiService fakeGemini(String text) => GeminiService(
  apiKey: 'test-key',
  client: MockClient((request) async => geminiAnswer(text)),
);
