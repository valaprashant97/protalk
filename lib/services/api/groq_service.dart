import 'dart:async';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service for generating AI responses and structured analytics via Groq Chat API.
class GroqService {
  static final GroqService _instance = GroqService._internal();
  factory GroqService() => _instance;
  GroqService._internal();

  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String defaultModel = 'openai/gpt-oss-20b';

  String _model = defaultModel;
  String get model => dotenv.env['GROQ_MODEL']?.trim().isNotEmpty == true
      ? dotenv.env['GROQ_MODEL']!.trim()
      : _model;

  void setModel(String model) {
    _model = model.trim().isNotEmpty ? model.trim() : defaultModel;
  }

  String _getApiKey() {
    final apiKey = dotenv.env['GROQ_API_AI_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      final fallback = dotenv.env['GROQ_API_KEY']?.trim() ?? '';
      if (fallback.isNotEmpty) return fallback;
      throw Exception("GROQ_API_AI_KEY is not set in .env file.");
    }
    return apiKey;
  }

  /// Generates a streaming response using Groq Chat Completions SSE
  Stream<String> generateStream(String prompt) async* {
    final apiKey = _getApiKey();
    final uri = Uri.parse(_baseUrl);

    final request = http.Request("POST", uri);
    request.headers.addAll({
      "Authorization": "Bearer $apiKey",
      "Content-Type": "application/json",
    });

    request.body = jsonEncode({
      "model": model,
      "messages": [
        {"role": "user", "content": prompt}
      ],
      "stream": true,
      "temperature": 0.7,
      "max_tokens": 1024,
    });

    http.StreamedResponse response;
    final client = http.Client();
    try {
      response = await client.send(request);
    } catch (e) {
      client.close();
      throw Exception("Could not connect to Groq API: $e");
    }

    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      client.close();
      throw Exception("Groq API error (${response.statusCode}): $errorBody");
    }

    final stream = response.stream.transform(utf8.decoder).transform(const LineSplitter());
    try {
      await for (final rawLine in stream) {
        final line = rawLine.trim();
        if (line.isEmpty) continue;
        if (!line.startsWith("data:")) continue;

        final dataStr = line.substring(5).trim();
        if (dataStr == "[DONE]") break;

        try {
          final data = jsonDecode(dataStr);
          final choices = data['choices'] as List?;
          if (choices != null && choices.isNotEmpty) {
            final delta = choices[0]['delta'] as Map?;
            if (delta != null) {
              final content = delta['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
            }
          }
        } catch (_) {
          // Ignore partial or malformed chunk parses
        }
      }
    } finally {
      client.close();
    }
  }

  /// Generates a complete response (non-streamed fallback)
  Future<String> generateResponse(
    String prompt, {
    Duration timeout = const Duration(seconds: 30),
    double temperature = 0.7,
    int maxTokens = 1024,
  }) async {
    final apiKey = _getApiKey();
    final uri = Uri.parse(_baseUrl);

    try {
      final response = await http
          .post(
            uri,
            headers: {
              "Authorization": "Bearer $apiKey",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "model": model,
              "messages": [
                {"role": "user", "content": prompt}
              ],
              "stream": false,
              "temperature": temperature,
              "max_tokens": maxTokens,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map?;
          return message?['content'] as String? ?? "";
        }
        return "";
      } else {
        throw Exception("Groq API error (${response.statusCode}): ${response.body}");
      }
    } on TimeoutException {
      throw Exception("Groq API timed out after ${timeout.inSeconds} seconds.");
    } catch (e) {
      throw Exception("Failed to generate response from Groq: $e");
    }
  }

  /// Fast structured JSON generation using Groq json_object response format
  Future<String> generateStructuredJson(
    String prompt, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final apiKey = _getApiKey();
    final uri = Uri.parse(_baseUrl);

    try {
      final response = await http
          .post(
            uri,
            headers: {
              "Authorization": "Bearer $apiKey",
              "Content-Type": "application/json",
            },
            body: jsonEncode({
              "model": model,
              "messages": [
                {"role": "user", "content": prompt}
              ],
              "stream": false,
              "response_format": {"type": "json_object"},
              "temperature": 0.2,
              "max_tokens": 2048,
            }),
          )
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices[0]['message'] as Map?;
          return message?['content'] as String? ?? "";
        }
        return "";
      } else {
        throw Exception("Groq API error (${response.statusCode}): ${response.body}");
      }
    } on TimeoutException {
      throw Exception("AI review generation timed out after ${timeout.inSeconds} seconds.");
    } catch (e) {
      throw Exception("Failed to generate structured JSON: $e");
    }
  }
}
