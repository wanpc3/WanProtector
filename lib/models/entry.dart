import '../encryption_helper.dart';

class Entry {
  final int? id;
  final String title;
  final String username;
  final String? password;
  final String? url;
  final String? notes;
  final String createdAt;
  final String lastUpdated;

  Entry({
    this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.url,
    required this.notes,
    required this.createdAt,
    required this.lastUpdated,
  });

  static Future<Entry> fromMapAsync(Map<String, dynamic> map) async {
    return Entry(
      id: map['id'],
      title: map['title'],
      username: await EncryptionHelper.decryptText(map['username']),
      password: await EncryptionHelper.decryptText(map['password']),
      url: map['url'],
      notes: await EncryptionHelper.decryptText(map['notes']),
      createdAt: map['created_at'],
      lastUpdated: map['last_updated'],
    );
  }

  Future<Map<String, dynamic>> toMapAsync() async {
    return {
      'id': id,
      'title': title,
      'username': await EncryptionHelper.encryptText(username ?? ''),
      'password': await EncryptionHelper.encryptText(password ?? ''),
      'url': url ?? '',
      'notes': await EncryptionHelper.encryptText(notes ?? ''),
      'created_at': createdAt,
      'last_updated': lastUpdated,
    };
  }
}