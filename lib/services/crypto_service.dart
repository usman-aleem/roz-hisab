import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypts the actual app data (shopping lists, udhar entries, bills)
/// before it's written to SharedPreferences, and decrypts it on read.
///
/// WHY: SharedPreferences on its own is plain, unencrypted XML on
/// Android — readable by anyone with root access or an `adb backup`
/// of the device. That's fine for app *settings*, but this app
/// stores real financial data (who owes whom, how much), so it's
/// encrypted at rest with AES-256. The encryption key itself never
/// touches SharedPreferences — it lives only in flutter_secure_storage
/// (Android Keystore / iOS Keychain).
class CryptoService {
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'roz_hisab_data_encryption_key';

  enc.Encrypter? _encrypter;

  Future<void> _ensureKey() async {
    if (_encrypter != null) return;

    String? keyStr = await _storage.read(key: _keyName);
    if (keyStr == null) {
      final newKey = enc.Key.fromSecureRandom(32); // AES-256
      keyStr = newKey.base64;
      await _storage.write(key: _keyName, value: keyStr);
    }
    final key = enc.Key.fromBase64(keyStr);
    _encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  /// Returns "ivBase64:cipherBase64" — a fresh random IV every call.
  Future<String> encryptString(String plainText) async {
    await _ensureKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter!.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Returns null if the payload can't be decrypted (wrong/missing
  /// key, corrupted data) — caller falls back gracefully instead of
  /// crashing.
  Future<String?> decryptString(String payload) async {
    try {
      await _ensureKey();
      final parts = payload.split(':');
      if (parts.length != 2) return null;
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (_) {
      return null;
    }
  }
}
