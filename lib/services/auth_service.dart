import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Handles the optional App Lock (PIN + biometric).
///
/// The PIN is never stored in plain text — only a SHA-256 hash of it,
/// inside flutter_secure_storage (Android Keystore / iOS Keychain —
/// encrypted at rest, unlike SharedPreferences which is plain XML).
class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _keyPinHash = 'roz_hisab_pin_hash';
  final LocalAuthentication _localAuth = LocalAuthentication();

  String _hash(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<bool> hasPin() async {
    final hash = await _storage.read(key: _keyPinHash);
    return hash != null && hash.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _keyPinHash, value: _hash(pin));
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _storage.read(key: _keyPinHash);
    if (storedHash == null) return false;
    return storedHash == _hash(pin);
  }

  Future<void> disableLock() async {
    await _storage.delete(key: _keyPinHash);
  }

  Future<bool> canUseBiometrics() async {
    if (kIsWeb) return false; // browsers don't expose device biometrics
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      return supported && canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Confirm your identity to open Roz Hisab',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
