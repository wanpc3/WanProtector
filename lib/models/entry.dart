class Entry {
  final int? id;
  final String title;
  final String username;
  final String password;
  final String url;
  final String notes;
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

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
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
      'id': id,
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