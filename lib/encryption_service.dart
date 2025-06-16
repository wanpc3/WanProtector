import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static final _secureStorage = FlutterSecureStorage();
  static final _iv = IV.fromLength(16); // AES block size is 16 bytes

  static Future<Encrypter> _getEncrypter() async {
    final key = await _getOrCreateEncryptionKey();
    return Encrypter(AES(key)); // Use the Key directly
  }

  static Future<Key> _getOrCreateEncryptionKey() async {
    const keyName = 'encryption_key';
    var keyString = await _secureStorage.read(key: keyName);
    
    if (keyString == null || keyString.isEmpty) {
      // Generate a new 256-bit (32-byte) key
      final newKey = Key.fromSecureRandom(32);
      keyString = newKey.base64;
      await _secureStorage.write(key: keyName, value: keyString);
      return newKey;
    }
    
    // Convert the stored base64 key back to a Key object
    return Key.fromBase64(keyString);
  }

  static Future<String> encrypt(String plaintext) async {
    if (plaintext.isEmpty) return plaintext;
    try {
      final encrypter = await _getEncrypter();
      final encrypted = encrypter.encrypt(plaintext, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      rethrow;
    }
  }

  static Future<String> decrypt(String ciphertext) async {
    if (ciphertext.isEmpty) return ciphertext;
    try {
      final encrypter = await _getEncrypter();
      return encrypter.decrypt64(ciphertext, iv: _iv);
    } catch (e) {
      print('Decryption error: $e');
      rethrow;
    }
  }
}