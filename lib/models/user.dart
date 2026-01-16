class User {
  final int id;
  final String username;
  final String email;
  final String storeName;
  final String role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.storeName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      storeName: json['nama_toko'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nama_toko': storeName,
      'role': role,
    };
  }

  // Helper methods
  bool get isAdmin => role == 'admin';
  bool get isToko => role == 'toko';
  String get displayRole => role == 'toko' ? 'Toko' : 'Admin';
}

class LoginResponse {
  final String token;
  final String role;
  final String storeName;

  LoginResponse({
    required this.token,
    required this.role,
    required this.storeName,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'],
      role: json['role'],
      storeName: json['nama_toko'],
    );
  }
}