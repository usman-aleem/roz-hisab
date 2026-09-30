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
  static const _keySecurityQuestion = 'roz_hisab_security_question';
  static const _keySecurityAnswerHash = 'roz_hisab_security_answer_hash';
  final LocalAuthentication _localAuth = LocalAuthentication();

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();

  /// Answers are normalized (trimmed + lowercased) before hashing so
  /// "Ahmed" and "ahmed " both verify correctly — people rarely type
  /// a security answer with consistent casing/spacing months later.
  String _normalizeAnswer(String answer) => answer.trim().toLowerCase();

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

  /// Removes the PIN only — used once a "Forgot PIN" reset is fully
  /// verified via the security question, right before a new PIN is
  /// set. Does NOT touch the security question itself, so the same
  /// question/answer keeps working for future resets.
  Future<void> disableLock() async {
    await _storage.delete(key: _keyPinHash);
  }

  /// Saved once, at PIN setup time — a self-chosen question (e.g.
  /// "What's your favorite personality?") with a memorable answer,
  /// used later to prove identity if the PIN itself is forgotten.
  /// Only the answer's hash is stored, never the plain answer.
  Future<void> setSecurityQuestion(String question, String answer) async {
    await _storage.write(key: _keySecurityQuestion, value: question);
    await _storage.write(
      key: _keySecurityAnswerHash,
      value: _hash(_normalizeAnswer(answer)),
    );
  }

  Future<bool> hasSecurityQuestion() async {
    final q = await _storage.read(key: _keySecurityQuestion);
    return q != null && q.isNotEmpty;
  }

  Future<String?> getSecurityQuestion() async {
    return _storage.read(key: _keySecurityQuestion);
  }

  /// True only if [answer] matches what was set at PIN-creation time.
  /// A wrong answer never resets or reveals anything about the PIN.
  Future<bool> verifySecurityAnswer(String answer) async {
    final storedHash = await _storage.read(key: _keySecurityAnswerHash);
    if (storedHash == null) return false;
    return storedHash == _hash(_normalizeAnswer(answer));
  }

  Future<void> clearSecurityQuestion() async {
    await _storage.delete(key: _keySecurityQuestion);
    await _storage.delete(key: _keySecurityAnswerHash);
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