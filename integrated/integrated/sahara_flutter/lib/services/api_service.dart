import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // ────────────────────────────────────────────────────────────────────
  // Base URL – running Flutter on Chrome, backend on same machine
  // ────────────────────────────────────────────────────────────────────
  static const String _baseUrl = 'http://localhost:5000';
  static const Duration _timeout = Duration(seconds: 90);

  // ── Health Check ────────────────────────────────────────────────────
  static Future<HealthStatus> checkHealth() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return HealthStatus(
          isOnline: true,
          llmLoaded: data['llm_loaded'] == true,
          memoriesIndexed: data['memories_indexed'] == true,
        );
      }
      return HealthStatus(isOnline: false);
    } catch (_) {
      return HealthStatus(isOnline: false);
    }
  }

  // ── Import WhatsApp Chat ─────────────────────────────────────────────
  // Takes bytes + filename — works on web AND mobile (no dart:io needed)
  static Future<int> importChat(Uint8List fileBytes, String fileName) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/import'),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'chat_file',
        fileBytes,
        filename: fileName,
      ),
    );

    final streamed = await request.send().timeout(_timeout);
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return (data['message_count'] as num?)?.toInt() ??
             (data['indexed'] as num?)?.toInt() ?? 0;
    }
    final err = _parseError(resp.body);
    throw Exception('Import failed: $err');
  }

  // ── Text Query ──────────────────────────────────────────────────────
  static Future<GenerateResponse> generate(String query) async {
    final resp = await http
        .post(
          Uri.parse('$_baseUrl/generate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'query': query}),
        )
        .timeout(_timeout);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return GenerateResponse(
        response: data['response'] as String? ?? '',
        isCrisis: data['is_crisis'] as bool? ?? false,
        retrievedCount: (data['retrieved_count'] as num?)?.toInt() ?? 0,
        memoriesSample: _parseMemories(data['memories_sample']),
      );
    }
    throw Exception('Server error ${resp.statusCode}: ${_parseError(resp.body)}');
  }

  // ── Voice Query ─────────────────────────────────────────────────────
  // Takes bytes + filename — works on web AND mobile (no dart:io needed)
  static Future<VoiceResponse> voiceQuery(
    Uint8List audioBytes,
    String fileName, {
    String lang = 'hi',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/voice_query'),
    );
    request.files.add(
      http.MultipartFile.fromBytes(
        'audio',
        audioBytes,
        filename: fileName,
      ),
    );
    request.fields['lang'] = lang;

    final streamed = await request.send().timeout(_timeout);
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return VoiceResponse(
        transcription: data['transcribed'] as String? ?? '',
        response: data['response'] as String? ?? '',
        isDistressed: data['is_distressed'] as bool? ?? false,
        isCrisis: data['is_crisis'] as bool? ?? false,
        distressScore: (data['distress_score'] as num?)?.toDouble() ?? 0.0,
        retrievedCount: (data['retrieved_count'] as num?)?.toInt() ?? 0,
        memoriesSample: _parseMemories(data['memories_sample']),
      );
    }
    throw Exception('Server error ${resp.statusCode}: ${_parseError(resp.body)}');
  }

  // ── Helpers ─────────────────────────────────────────────────────────
  static List<Memory> _parseMemories(dynamic raw) {
    if (raw == null) return [];
    try {
      return (raw as List)
          .map((m) => Memory.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String _parseError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['error']?.toString() ?? body;
    } catch (_) {
      return body;
    }
  }
}

// ── Response Models ──────────────────────────────────────────────────────

class HealthStatus {
  final bool isOnline;
  final bool llmLoaded;
  final bool memoriesIndexed;

  const HealthStatus({
    required this.isOnline,
    this.llmLoaded = false,
    this.memoriesIndexed = false,
  });

  bool get isReady => isOnline && llmLoaded;
}

class GenerateResponse {
  final String response;
  final bool isCrisis;
  final int retrievedCount;
  final List<Memory> memoriesSample;

  const GenerateResponse({
    required this.response,
    required this.isCrisis,
    required this.retrievedCount,
    required this.memoriesSample,
  });
}

class VoiceResponse {
  final String transcription;
  final String response;
  final bool isDistressed;
  final bool isCrisis;
  final double distressScore;
  final int retrievedCount;
  final List<Memory> memoriesSample;

  const VoiceResponse({
    required this.transcription,
    required this.response,
    required this.isDistressed,
    required this.isCrisis,
    required this.distressScore,
    required this.retrievedCount,
    required this.memoriesSample,
  });
}