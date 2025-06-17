import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionHelper {
  static const _storage = FlutterSecureStorage();
  static const _keyIdentifier = 'encryption_key';

  static Future<encrypt.Key> _getEncryptionKey() async {
    final existingKey = await _storage.read(key: _keyIdentifier);
    if (existingKey != null) {
      return encrypt.Key.fromBase64(existingKey);
    }

    //Generate new key
    final random = Random.secure();
    final keyBytes = Uint8List(32);
    for (var i = 0; i < keyBytes.length; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    final newKey = encrypt.Key(keyBytes);

    await _storage.write(
      key: _keyIdentifier, 
      value: newKey.base64
    );

    return newKey;
  }

  static encrypt.IV _generateIV() {
    final random = Random.secure();
    final ivBytes = Uint8List(16);
    for (var i = 0; i < ivBytes.length; i++) {
      ivBytes[i] = random.nextInt(256);
    }
    return encrypt.IV(ivBytes);
  }

  //Encrypt with AES-256-CBC + HMAC-SHA256
  static Future<String> encryptText(String plainText) async {
    final key = await _getEncryptionKey();
    final iv = _generateIV();
    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc)
    );

    //Encrypt
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    //Combine IV + cipherText + HMAC
    final hmac = Hmac(sha256, key.bytes);
    final authCode = hmac.convert([...iv.bytes, ...encrypted.bytes]).bytes;

    return base64.encode([...iv.bytes, ...encrypted.bytes, ...authCode]);
  }

  //Decrypt with verification
  static Future<String> decryptText(String encryptedText) async {
    try {
      final key = await _getEncryptionKey();
      final data = base64.decode(encryptedText);

      final iv = encrypt.IV(data.sublist(0, 16));
      final cipherText = data.sublist(16, data.length - 32);
      final receivedHmac = data.sublist(data.length - 32);

      final hmac = Hmac(sha256, key.bytes);
      final computedHmac = hmac.convert([...iv.bytes, ...cipherText]).bytes;

      if (!_constantTimeCompare(receivedHmac, computedHmac)) {
        throw Exception('HMAC verification failed');
      }

      //Decrypt
      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc)
      );
      final decrypted = encrypter.decryptBytes(encrypt.Encrypted(cipherText), iv: iv);
      return utf8.decode(decrypted);
    } catch (e) {
      return '';
    }
  }

  //Constant-time comparison to prevent timing attacks
  static bool _constantTimeCompare(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}