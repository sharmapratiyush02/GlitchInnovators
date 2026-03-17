import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

enum AuthResult {
  success,
  failure,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentLockout,
  cancelled,
  error,
}

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final _auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  static const _enabledKey = 'biometric_enabled';
  static const _lastAuthKey = 'last_auth_ts';
  static const _lockDuration = Duration(minutes: 5);

  // ── Capabilities ───────────────────────────────────────────────────────
  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();
  Future<bool> isEnrolled() async {
    final types = await _auth.getAvailableBiometrics();
    return types.isNotEmpty;
  }

  Future<bool> isFaceAvailable() async {
    final types = await _auth.getAvailableBiometrics();
    return types.contains(BiometricType.face);
  }

  // ── Enable / Disable ───────────────────────────────────────────────────
  Future<bool> isEnabled() async {
    final val = await _storage.read(key: _enabledKey);
    return val == 'true';
  }

  Future<void> setEnabled(bool value) async {
    await _storage.write(key: _enabledKey, value: value.toString());
  }

  // ── Auto-lock ──────────────────────────────────────────────────────────
  Future<void> recordSuccess() async {
    await _storage.write(
      key: _lastAuthKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<bool> shouldRelock() async {
    final ts = await _storage.read(key: _lastAuthKey);
    if (ts == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(int.parse(ts));
    return DateTime.now().difference(last) > _lockDuration;
  }

  // ── Authenticate ───────────────────────────────────────────────────────
  Future<AuthResult> authenticate({String? reason}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason ?? 'Authenticate to access Sahara',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (ok) {
        await recordSuccess();
        return AuthResult.success;
      }
      return AuthResult.failure;
    } on PlatformException catch (e) {
      return _mapException(e);
    }
  }

  AuthResult _mapException(PlatformException e) {
    switch (e.code) {
      case 'NotAvailable':
        return AuthResult.notAvailable;
      case 'NotEnrolled':
        return AuthResult.notEnrolled;
      case 'LockedOut':
        return AuthResult.lockedOut;
      case 'PermanentlyLockedOut':
        return AuthResult.permanentLockout;
      case 'Cancelled':
        return AuthResult.cancelled;
      default:
        return AuthResult.error;
    }
  }

  String describeResult(AuthResult result) {
    switch (result) {
      case AuthResult.success:
        return 'Authentication successful';
      case AuthResult.failure:
        return 'Authentication failed. Please try again.';
      case AuthResult.notAvailable:
        return 'Biometric authentication is not available on this device.';
      case AuthResult.notEnrolled:
        return 'No biometrics enrolled. Please set up Face ID or fingerprint in Settings.';
      case AuthResult.lockedOut:
        return 'Too many attempts. Please try again later.';
      case AuthResult.permanentLockout:
        return 'Biometrics locked. Please use your device PIN to unlock.';
      case AuthResult.cancelled:
        return 'Authentication cancelled.';
      case AuthResult.error:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
