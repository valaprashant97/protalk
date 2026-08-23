import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Service to perform Speech-to-Text transcription via Groq Whisper API.
class GroqWhisperService {
  static const String _baseUrl = 'https://api.groq.com/openai/v1/audio/transcriptions';

  /// Transcribes an audio file at [audioPath] using Groq's Whisper model.
  Future<String> transcribe(String audioPath) async {
    final apiKey = dotenv.env['GROQ_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw Exception("GROQ_API_KEY is not set in .env file.");
    }

    final file = File(audioPath);
    if (!await file.exists()) {
      throw Exception("Audio file does not exist at path: $audioPath");
    }

    final request = http.MultipartRequest('POST', Uri.parse(_baseUrl))
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = 'whisper-large-v3-turbo'
      ..fields['response_format'] = 'json'
      ..files.add(await http.MultipartFile.fromPath('file', audioPath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['text'] as String? ?? '';
    } else {
      throw Exception("Groq API error (${response.statusCode}): ${response.body}");
    }
  }
}
