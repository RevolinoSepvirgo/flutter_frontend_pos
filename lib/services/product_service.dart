import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product.dart';
import '../models/category.dart';

class ProductService {
  // ===== PRODUCTS =====
  
  // Get All Products
  Future<List<Product>> getAllProducts(String token) async {
    try {
      final url = '${ApiConfig.productServiceUrl}/products';
      print('📡 GET Request: $url');
      print('🔑 Token: ${token.substring(0, 20)}...');
      
      final response = await http.get(
        Uri.parse(url),
        headers: ApiConfig.headers(token: token),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Parsed ${data.length} products');
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Gagal mengambil data produk');
      }
    } catch (e) {
      print('❌ Exception di getAllProducts: $e');
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Create Product
  Future<void> createProduct({
    required String token,
    required int categoryId,
    required String productName,
    required double price,
    required int stock,
    String? imageUrl,
  }) async {
    try {
      final body = {
        'category_id': categoryId,
        'nama_produk': productName,
        'harga': price,
        'stok': stock,
      };
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        body['gambar_produk'] = imageUrl;
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.productServiceUrl}/products'),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Gagal menambah produk');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Update Product
  Future<void> updateProduct({
    required String token,
    required int productId,
    required int categoryId,
    required String productName,
    required double price,
    required int stock,
    String? imageUrl,
  }) async {
    try {
      final body = {
        'category_id': categoryId,
        'nama_produk': productName,
        'harga': price,
        'stok': stock,
      };
      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        body['gambar_produk'] = imageUrl;
      }

      final response = await http.put(
        Uri.parse('${ApiConfig.productServiceUrl}/products/$productId'),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Gagal update produk');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Delete Product
  Future<void> deleteProduct(String token, int productId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.productServiceUrl}/products/$productId'),
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Gagal hapus produk');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // ===== CATEGORIES =====
  
  // Get All Categories
  Future<List<Category>> getAllCategories(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.productServiceUrl}/categories'),
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Gagal mengambil data kategori');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Create Category
  Future<void> createCategory({
    required String token,
    required String categoryName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.productServiceUrl}/categories'),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({
          'nama_kategori': categoryName,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Gagal menambah kategori');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Update Category
  Future<void> updateCategory({
    required String token,
    required int categoryId,
    required String categoryName,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.productServiceUrl}/categories/$categoryId'),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode({
          'nama_kategori': categoryName,
        }),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Gagal update kategori');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Delete Category
  Future<void> deleteCategory(String token, int categoryId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.productServiceUrl}/categories/$categoryId'),
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Gagal hapus kategori');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }
}