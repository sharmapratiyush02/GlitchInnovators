import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:5000';
  static const Duration _timeout = Duration(seconds: 30);

  // ── Health Check ────────────────────────────────────────────────────────
  static Future<bool> checkHealth() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['llm_loaded'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Text Query ──────────────────────────────────────────────────────────
  static Future<GenerateResponse> generate(String query) async {
    final resp = await http
        .post(
          Uri.parse('$_baseUrl/generate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'query': query}),
        )
        .timeout(_timeout);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return GenerateResponse(
        response: data['response'] ?? '',
        retrievedCount: data['retrieved_count'] ?? 0,
        memoriesSample: (data['memories_sample'] as List?)
                ?.map((m) => Memory.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
      );
    }
    throw HttpException('Server error ${resp.statusCode}');
  }

  // ── Voice Query ─────────────────────────────────────────────────────────
  static Future<VoiceResponse> voiceQuery(File audioFile) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/voice_query'),
    );
    request.files.add(
      await http.MultipartFile.fromPath('audio', audioFile.path),
    );

    final streamed = await request.send().timeout(_timeout);
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return VoiceResponse(
        transcription: data['transcription'] ?? '',
        response: data['response'] ?? '',
        isDistressed: data['is_distressed'] ?? false,
        isCrisis: data['is_crisis'] ?? false,
        retrievedCount: data['retrieved_count'] ?? 0,
        memoriesSample: (data['memories_sample'] as List?)
                ?.map((m) => Memory.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
      );
    }
    throw HttpException('Server error ${resp.statusCode}');
  }
}

class GenerateResponse {
  final String response;
  final int retrievedCount;
  final List<Memory> memoriesSample;

  const GenerateResponse({
    required this.response,
    required this.retrievedCount,
    required this.memoriesSample,
  });
}

class VoiceResponse {
  final String transcription;
  final String response;
  final bool isDistressed;
  final bool isCrisis;
  final int retrievedCount;
  final List<Memory> memoriesSample;

  const VoiceResponse({
    required this.transcription,
    required this.response,
    required this.isDistressed,
    required this.isCrisis,
    required this.retrievedCount,
    required this.memoriesSample,
  });
}
