class DeletedEntry {
  final int? deletedId;
  final String title;
  final String username;
  final String password;
  final String url;
  final String notes;
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

  factory DeletedEntry.fromMap(Map<String, dynamic> map) {
    return DeletedEntry(
      deletedId: map['deleted_id'],
      title: map['title'],
      username: map['username'],
      password: map['password'],
      url: map['url'],
      notes: map['notes'],
      createdAt: map['created_at'],
      lastUpdated: map['last_updated'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deleted_id': deletedId,
      'title': title,
      'username': username,
      'password': password,
      'url': url,
      'notes': notes,
      'created_at': createdAt,
      'last_updated': lastUpdated,
    };
  }
}