import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';

class EncryptionHelper {
  static final _key = encrypt.Key.fromUtf8(_generateKey('I-Am+=A#Stud3nt-(of),Hacking+=Fr0m:Mal@ysia.K33p+-=Learning,N0M@tt3r=-=What....///K33p+=H@cking4Good'));
  static final _iv = encrypt.IV.fromLength(16);

  static String _generateKey(String password) {
    final key = sha256.convert(utf8.encode(password)).toString().substring(0, 32);
    return key;
  }

  static String encryptText(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  static String decryptText(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}
