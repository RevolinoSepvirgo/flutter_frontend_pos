import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';

class AuthService {
  // Login
  Future<LoginResponse> login(String email, String password) async {
    try {
      final url = '${ApiConfig.userServiceUrl}/users/login';
      print('📡 Login URL: $url');
      print('📧 Email: $email');
      
      final response = await http.post(
        Uri.parse(url),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📥 Status Code: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Login gagal');
      }
    } catch (e) {
      print('❌ Login Exception: $e');
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Register
  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String storeName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.userServiceUrl}/users/register'),
        headers: ApiConfig.headers(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'nama_toko': storeName,
        }),
      );

      if (response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Registrasi gagal');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Get User Profile
  Future<User> getUserProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.userServiceUrl}/users/me'),
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Gagal mengambil profil');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Get All Users (Admin only)
  Future<List<User>> getAllUsers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.userServiceUrl}/users'),
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Gagal mengambil data user');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Create User (Admin only)
  Future<void> createUser({
    required String token,
    required String username,
    required String email,
    required String password,
    required String storeName,
    String role = 'toko',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.userServiceUrl}/users'),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'nama_toko': storeName,
          'role': role,
        }),
      );

      if (response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Gagal membuat user');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Update User
  Future<void> updateUser({
    required String token,
    required int userId,
    String? username,
    String? email,
    String? password,
    String? storeName,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (username != null) body['username'] = username;
      if (email != null) body['email'] = email;
      if (password != null) body['password'] = password;
      if (storeName != null) body['nama_toko'] = storeName;

      final response = await http.put(
        Uri.parse('${ApiConfig.userServiceUrl}/users/$userId'),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Gagal update user');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Delete User (Admin only)
  Future<void> deleteUser(String token, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.userServiceUrl}/users/$userId'),
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Gagal hapus user');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }
}