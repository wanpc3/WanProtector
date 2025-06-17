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

  factory MasterPassword.fromMap(Map<String, dynamic> map) {
    return MasterPassword(
      id: map['id'],
      password: map['password'], 
      createdAt: map['created_at'], 
      lastUpdated: map['last_updated'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'password': password,
      'created_at': createdAt,
      'last_updated': lastUpdated,
    };
  }
}