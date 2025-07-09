import '../encryption_helper.dart';

class DeletedEntry {
  final int? deletedId;
  final String title;
  final String username;
  final String? password;
  final String? url;
  final String? notes;
  final String createdAt;
  final String lastUpdated;

  DeletedEntry({
    this.deletedId,
    required this.title,
    required this.username,
    required this.password,
    required this.url,
    required this.notes,
    required this.createdAt,
    required this.lastUpdated,
  });

  //To display in View Deleted Entry
  static Future<DeletedEntry> fromMapAsync(Map<String, dynamic> map) async {
    return DeletedEntry(
      deletedId: map['deleted_id'],
      title: map['title'] ?? '',
      username: await EncryptionHelper.decryptText(map['username'] ?? ''),
      password: map['password'] != null ? await EncryptionHelper.decryptText(map['password']) : null,
      url: map['url'] ?? '',
      notes: map['notes'] != null ? await EncryptionHelper.decryptText(map['notes']) : null,
      createdAt: map['created_at'] ?? '',
      lastUpdated: map['last_updated'] ?? '',
    );
  }

  Future<Map<String, dynamic>> toMapAsync() async {
    return {
      'deleted_id': deletedId,
      'title': title,
      'username': await EncryptionHelper.encryptText(username),
      'password': await EncryptionHelper.encryptText(password ?? ''),
      'url': url ?? '',
      'notes': await EncryptionHelper.encryptText(notes ?? ''),
      'created_at': createdAt,
      'last_updated': lastUpdated,
    };
  }
}