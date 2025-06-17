import '../encryption_helper.dart';

class MasterPassword {
  final int? id;
  final String password;
  final String createdAt;
  final String lastUpdated;

  MasterPassword({
    this.id,
    required this.password,
    required this.createdAt,
    required this.lastUpdated,
  });

  static Future<MasterPassword> fromMapAsync(Map<String, dynamic> map) async {
    return MasterPassword(
      id: map['id'],
      password: await EncryptionHelper.decryptText(map['password']), 
      createdAt: map['created_at'], 
      lastUpdated: map['last_updated'],
    );
  }

  Future<Map<String, dynamic>> toMapAsync() async {
    return {
      'id': id,
      'password': await EncryptionHelper.encryptText(password),
      'created_at': createdAt,
      'last_updated': lastUpdated,
    };
  }
}