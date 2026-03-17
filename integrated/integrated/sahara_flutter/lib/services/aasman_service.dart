// lib/services/aasman_service.dart
// ─────────────────────────────────────────────────────────────
// Aasman — Sahara Gathering Flutter Service
//
// Handles all communication with the Aasman backend:
//   - Anonymous token management (generated & stored on-device)
//   - Sky stats, diya wall, whispers, ritual
//   - Real-time updates via Socket.IO
//   - Crisis response interception
//
// flutter pub add socket_io_client http flutter_secure_storage
// ─────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

// ─── Data models ─────────────────────────────────────────────

class SkyStats {
  final int starsTonight;
  final int whispersTonight;
  final RitualInfo ritual;

  SkyStats({
    required this.starsTonight,
    required this.whispersTonight,
    required this.ritual,
  });

  factory SkyStats.fromJson(Map<String, dynamic> j) => SkyStats(
    starsTonight:    j['stars_tonight']    ?? 0,
    whispersTonight: j['whispers_tonight'] ?? 0,
    ritual: RitualInfo.fromJson(j['ritual'] ?? {}),
  );
}

class RitualInfo {
  final bool isActive;
  final int  secondsUntilNext;
  final String ritualTimeIST;
  final String prompt;
  final int participantsNow;

  RitualInfo({
    required this.isActive,
    required this.secondsUntilNext,
    required this.ritualTimeIST,
    this.prompt = '',
    this.participantsNow = 0,
  });

  factory RitualInfo.fromJson(Map<String, dynamic> j) => RitualInfo(
    isActive:          j['is_active']           ?? false,
    secondsUntilNext:  j['seconds_until_next']  ?? 0,
    ritualTimeIST:     j['ritual_time_ist']     ?? '20:00 IST',
    prompt:            j['prompt']              ?? '',
    participantsNow:   j['participants_now']    ?? 0,
  );

  String get countdownFormatted {
    final m = secondsUntilNext ~/ 60;
    final s = secondsUntilNext % 60;
    return '$m:${s.toString().padLeft(2,'0')}';
  }
}

class Diya {
  final String color;
  final String intent;
  final String litAt;

  Diya({required this.color, required this.intent, required this.litAt});

  factory Diya.fromJson(Map<String, dynamic> j) => Diya(
    color:  j['color']  ?? '#d4874e',
    intent: j['intent'] ?? '',
    litAt:  j['lit_at'] ?? '',
  );
}

class Whisper {
  final String  id;
  final String  text;
  final String  color;
  final int     echoes;
  final String  sentAt;
  bool echoedByMe;

  Whisper({
    required this.id,
    required this.text,
    required this.color,
    required this.echoes,
    required this.sentAt,
    this.echoedByMe = false,
  });

  factory Whisper.fromJson(Map<String, dynamic> j) => Whisper(
    id:     j['id']      ?? '',
    text:   j['text']    ?? '',
    color:  j['color']   ?? '#d4874e',
    echoes: j['echoes']  ?? 0,
    sentAt: j['sent_at'] ?? '',
  );
}

// Crisis response model
class CrisisResponse {
  final String message;
  final List<Map<String, String>> resources;

  CrisisResponse({required this.message, required this.resources});

  factory CrisisResponse.fromJson(Map<String, dynamic> j) => CrisisResponse(
    message: j['message'] ?? '',
    resources: List<Map<String, String>>.from(
      (j['resources'] ?? []).map((r) => Map<String, String>.from(r))
    ),
  );
}

// Result wrapper
sealed class AasmanResult<T> {}
class AasmanSuccess<T> extends AasmanResult<T> {
  final T data;
  AasmanSuccess(this.data);
}
class AasmanError<T> extends AasmanResult<T> {
  final String message;
  final String? code;
  AasmanError(this.message, {this.code});
}
class AasmanCrisis<T> extends AasmanResult<T> {
  final CrisisResponse response;
  AasmanCrisis(this.response);
}

// ─── Service ──────────────────────────────────────────────────

class AasmanService extends ChangeNotifier {
  AasmanService._();
  static final AasmanService instance = AasmanService._();

  static const _baseUrl    = 'http://localhost:5001'; // change to your prod URL
  static const _tokenKey   = 'aasman_anon_token';
  static const _diyaLitKey = 'aasman_diya_date';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Real-time socket
  io.Socket? _socket;

  // Reactive state
  SkyStats?     skyStats;
  List<Diya>    diyas    = [];
  List<Whisper> whispers = [];
  RitualInfo?   ritual;
  bool          diyaLitToday = false;
  bool          whisperSentToday = false;
  int           ritualParticipants = 0;

  String? _token;

  // ── Token management ──────────────────────────────────────

  Future<String> get token async {
    _token ??= await _storage.read(key: _tokenKey);
    if (_token == null) {
      await _issueToken();
    }
    return _token!;
  }

  Future<void> _issueToken() async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/token'),
        headers: {'Content-Type': 'application/json'},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['token'];
        await _storage.write(key: _tokenKey, value: _token);
      }
    } catch (e) {
      // Generate a local fallback token (offline mode)
      _token = _generateLocalToken();
      await _storage.write(key: _tokenKey, value: _token);
    }
  }

  String _generateLocalToken() {
    final rand  = Random.secure();
    final bytes = List<int>.generate(32, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  Future<Map<String, String>> get _headers async => {
    'Content-Type':    'application/json',
    'X-Aasman-Token':  await token,
  };

  // ── HTTP helpers ──────────────────────────────────────────

  Future<Map<String, dynamic>?> _get(String path) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl$path'),
        headers: await _headers,
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
      return null;
    } catch (_) { return null; }
  }

  Future<http.Response?> _post(String path, Map<String, dynamic> body) async {
    try {
      return await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: await _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
    } catch (_) { return null; }
  }

  // ── Sky stats ─────────────────────────────────────────────

  Future<void> loadSky() async {
    final data = await _get('/api/sky');
    if (data != null) {
      skyStats = SkyStats.fromJson(data);
      notifyListeners();
    }
    await _checkDiyaStatus();
  }

  // ── Diyas ─────────────────────────────────────────────────

  Future<void> loadDiyas() async {
    final data = await _get('/api/diyas');
    if (data != null) {
      diyas = (data['diyas'] as List? ?? [])
          .map((d) => Diya.fromJson(d))
          .toList();
      notifyListeners();
    }
  }

  Future<AasmanResult<Diya>> lightDiya({
    required String color,
    String intent = '',
  }) async {
    final res = await _post('/api/diyas', {
      'color':  color,
      'intent': intent,
    });

    if (res == null) return AasmanError('No connection');

    final body = jsonDecode(res.body);

    if (res.statusCode == 200 && body['error'] == 'crisis') {
      return AasmanCrisis(CrisisResponse.fromJson(body['response']));
    }
    if (res.statusCode == 409) {
      return AasmanError('Already lit today', code: 'already_lit');
    }
    if (res.statusCode == 201) {
      final diya = Diya.fromJson(body['diya']);
      diyaLitToday = true;
      // Persist locally so we know even offline
      await _storage.write(
        key: _diyaLitKey,
        value: DateTime.now().toIso8601String().substring(0, 10),
      );
      diyas.insert(0, diya);
      skyStats = SkyStats(
        starsTonight: (skyStats?.starsTonight ?? 0) + 1,
        whispersTonight: skyStats?.whispersTonight ?? 0,
        ritual: skyStats?.ritual ?? RitualInfo(isActive: false, secondsUntilNext: 0, ritualTimeIST: ''),
      );
      notifyListeners();
      return AasmanSuccess(diya);
    }

    return AasmanError(body['error'] ?? 'Unknown error');
  }

  Future<void> _checkDiyaStatus() async {
    final stored = await _storage.read(key: _diyaLitKey);
    final today  = DateTime.now().toIso8601String().substring(0, 10);
    diyaLitToday = stored == today;
    notifyListeners();
  }

  // ── Whispers ──────────────────────────────────────────────

  Future<void> loadWhispers() async {
    final data = await _get('/api/whispers?limit=20');
    if (data != null) {
      whispers = (data['whispers'] as List? ?? [])
          .map((w) => Whisper.fromJson(w))
          .toList();
      notifyListeners();
    }
  }

  Future<AasmanResult<Whisper>> sendWhisper({
    required String text,
    String color = '#d4874e',
  }) async {
    if (text.trim().isEmpty) return AasmanError('Text required');
    if (text.length > 120)   return AasmanError('Max 120 characters');

    final res = await _post('/api/whispers', {'text': text.trim(), 'color': color});
    if (res == null) return AasmanError('No connection');

    final body = jsonDecode(res.body);

    if (res.statusCode == 200 && body['error'] == 'crisis') {
      return AasmanCrisis(CrisisResponse.fromJson(body['response']));
    }
    if (res.statusCode == 409) {
      return AasmanError('One whisper per day', code: 'limit_reached');
    }
    if (res.statusCode == 201) {
      final w = Whisper.fromJson(body['whisper']);
      whispers.insert(0, w);
      whisperSentToday = true;
      notifyListeners();
      return AasmanSuccess(w);
    }

    return AasmanError(body['error'] ?? 'Unknown error');
  }

  Future<void> toggleEcho(Whisper whisper) async {
    if (whisper.id.isEmpty) return;
    final res = await _post('/api/whispers/${whisper.id}/echo', {});
    if (res == null) return;
    final body = jsonDecode(res.body);
    if (body['success'] == true) {
      whisper.echoedByMe = !whisper.echoedByMe;
      notifyListeners();
    }
  }

  // ── Ritual ────────────────────────────────────────────────

  Future<void> loadRitual() async {
    final data = await _get('/api/ritual');
    if (data != null) {
      ritual = RitualInfo.fromJson({
        ...data['ritual'] ?? {},
        'prompt':            data['prompt']            ?? '',
        'participants_now':  data['participants_now']  ?? 0,
      });
      ritualParticipants = data['participants_now'] ?? 0;
      notifyListeners();
    }
  }

  Future<void> joinRitual() async {
    await _post('/api/ritual/join', {});
    _socket?.emit('join_ritual', {});
  }

  Future<void> leaveRitual() async {
    await _post('/api/ritual/leave', {});
    _socket?.emit('leave_ritual', {});
  }

  // ── Real-time Socket.IO ───────────────────────────────────

  void connectRealtime() {
    _socket?.disconnect();
    _socket = io.io(_baseUrl, <String, dynamic>{
      'transports':     ['websocket'],
      'autoConnect':    true,
      'reconnection':   true,
      'reconnectionAttempts': 5,
    });

    _socket!.onConnect((_) {
      debugPrint('Aasman socket connected');
    });

    // New diya lit by anyone
    _socket!.on('diya_lit', (data) {
      final diya = Diya.fromJson(Map<String, dynamic>.from(data));
      diyas.insert(0, diya);
      if (skyStats != null) {
        skyStats = SkyStats(
          starsTonight: skyStats!.starsTonight + 1,
          whispersTonight: skyStats!.whispersTonight,
          ritual: skyStats!.ritual,
        );
      }
      notifyListeners();
    });

    // New whisper from anyone
    _socket!.on('new_whisper', (data) {
      final w = Whisper.fromJson(Map<String, dynamic>.from(data));
      whispers.insert(0, w);
      if (skyStats != null) {
        skyStats = SkyStats(
          starsTonight: skyStats!.starsTonight,
          whispersTonight: skyStats!.whispersTonight + 1,
          ritual: skyStats!.ritual,
        );
      }
      notifyListeners();
    });

    // Ritual participant count update
    _socket!.on('ritual_participant_count', (data) {
      ritualParticipants = data['count'] ?? 0;
      notifyListeners();
    });

    _socket!.onDisconnect((_) {
      debugPrint('Aasman socket disconnected');
    });

    _socket!.onError((e) {
      debugPrint('Aasman socket error: $e');
    });
  }

  void disconnectRealtime() {
    _socket?.disconnect();
    _socket = null;
  }

  @override
  void dispose() {
    disconnectRealtime();
    super.dispose();
  }
}