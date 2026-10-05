import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// The key from config/dev.json, passed in with --dart-define-from-file.
/// Empty when the app runs without that file, e.g. right after cloning.
const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

/// A call to Gemini that failed: no internet, no answer in time, the free
/// limit reached (429), a refused key, or an answer in an unexpected shape.
/// [message] is for the logs; the screens say what happened in their own
/// words, in the language of the app.
class GeminiException implements Exception {
  const GeminiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// True when the free tier's limit is reached for now.
  bool get isQuotaExceeded => statusCode == 429;

  @override
  String toString() => 'GeminiException($statusCode): $message';
}

/// Text from Google's Gemini models, through their REST API. The app works
/// without it: the assistant then answers only by its rules.
class GeminiService {
  GeminiService({
    required this.apiKey,
    this.model = 'gemini-3.5-flash-lite',
    this.timeout = const Duration(seconds: 15),
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;

  /// The fastest and cheapest stable model in October 2026.
  final String model;

  final Duration timeout;

  /// Tests pass a MockClient here, so they never reach the internet.
  final http.Client _client;

  /// Sends [prompt] to the model, which follows [instructions], and returns
  /// the text of its answer.
  Future<String> generate(String prompt, {required String instructions}) async {
    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$model:generateContent',
    );
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': apiKey,
            },
            body: jsonEncode({
              'systemInstruction': {
                'parts': [
                  {'text': instructions},
                ],
              },
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const GeminiException('Gemini did not answer in time.');
    } on http.ClientException catch (error) {
      throw GeminiException('No connection: ${error.message}');
    }

    if (response.statusCode != 200) {
      throw GeminiException(
        'Gemini refused the request.',
        statusCode: response.statusCode,
      );
    }
    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      // The text sits at candidates[0].content.parts[0].text. The pattern
      // checks that shape and reads the text in one step.
      if (json case {
        'candidates': [
          {'content': {'parts': [{'text': final String text}, ...]}},
          ...,
        ],
      }) {
        return text.trim();
      }
    } on FormatException {
      // Not JSON at all: handled below, like any other unexpected answer.
    }
    throw const GeminiException('Gemini sent an unexpected answer.');
  }
}
