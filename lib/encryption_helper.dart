import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionHelper {
  // Version prefix for future compatibility
  static const _versionPrefix = 'v2:';
  static const _keyIdentifier = 'encryption_key_v2';
  static const _storage = FlutterSecureStorage();

  // Cache the key to avoid repeated secure storage access
  static encrypt.Key? _cachedKey;

  /// Initialize with a key from secure storage or generate a new one
  static Future<void> initialize() async {
    if (_cachedKey != null) return;

    // Try to load existing key
    final existingKey = await _storage.read(key: _keyIdentifier);
    if (existingKey != null && existingKey.length >= 32) {
      _cachedKey = encrypt.Key.fromBase64(existingKey);
      return;
    }

    // Generate new secure key
    final random = Random.secure();
    final keyBytes = Uint8List(32);
    for (var i = 0; i < keyBytes.length; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    _cachedKey = encrypt.Key(keyBytes);
    
    // Store securely
    await _storage.write(
      key: _keyIdentifier,
      value: _cachedKey!.base64,
    );
  }

  /// Clear cached key (for testing or logout scenarios)
  static Future<void> clearKey() async {
    _cachedKey = null;
    await _storage.delete(key: _keyIdentifier);
  }

  static encrypt.IV _generateIV() {
    final random = Random.secure();
    final ivBytes = Uint8List(16);
    for (var i = 0; i < ivBytes.length; i++) {
      ivBytes[i] = random.nextInt(256);
    }
    return encrypt.IV(ivBytes);
  }

  /// Encrypts text with AES-256-CBC + HMAC-SHA256 authentication
  static Future<String> encryptText(String plainText) async {
    if (plainText.isEmpty) return '';
    await initialize();

    try {
      final iv = _generateIV();
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_cachedKey!, mode: encrypt.AESMode.cbc),
      );

      final encrypted = encrypter.encrypt(plainText, iv: iv);

      // Add HMAC for authentication
      final hmac = Hmac(sha256, _cachedKey!.bytes);
      final authCode = hmac.convert([...iv.bytes, ...encrypted.bytes]).bytes;

      return _versionPrefix + base64.encode([...iv.bytes, ...encrypted.bytes, ...authCode]);
    } catch (e) {
      debugPrint('Encryption error: $e');
      return '';
    }
  }

  /// Decrypts text with HMAC verification
  static Future<String> decryptText(String encryptedText) async {
    if (encryptedText.isEmpty || !encryptedText.startsWith(_versionPrefix)) {
      return '';
    }
    await initialize();

    try {
      final data = base64.decode(encryptedText.substring(_versionPrefix.length));
      if (data.length < 48) return ''; // IV(16) + HMAC(32) minimum

      final iv = encrypt.IV(data.sublist(0, 16));
      final cipherText = data.sublist(16, data.length - 32);
      final receivedHmac = data.sublist(data.length - 32);

      // Verify HMAC
      final hmac = Hmac(sha256, _cachedKey!.bytes);
      final computedHmac = hmac.convert([...iv.bytes, ...cipherText]).bytes;

      if (!_constantTimeCompare(receivedHmac, computedHmac)) {
        debugPrint('HMAC verification failed');
        return '';
      }

      final encrypter = encrypt.Encrypter(
        encrypt.AES(_cachedKey!, mode: encrypt.AESMode.cbc),
      );

      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(cipherText),
        iv: iv,
      );

      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint('Decryption error: $e');
      return '';
    }
  }

  /// Constant-time comparison to prevent timing attacks
  static bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Backup the encryption key to a secure location
  static Future<String?> backupKey() async {
    await initialize();
    return _cachedKey?.base64;
  }

  /// Restore the encryption key from backup
  static Future<bool> restoreKey(String base64Key) async {
    try {
      final key = encrypt.Key.fromBase64(base64Key);
      if (key.bytes.length != 32) return false;
      
      _cachedKey = key;
      await _storage.write(key: _keyIdentifier, value: base64Key);
      return true;
    } catch (e) {
      debugPrint('Key restore error: $e');
      return false;
    }
  }
}