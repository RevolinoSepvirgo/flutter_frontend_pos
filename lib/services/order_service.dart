import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:point_of_sales_flutter/models/order.dart';

class OrderService {
  // Ganti dengan IP laptop jika pakai emulator (10.0.2.2) atau IP Server
  final String baseUrl = "http://10.0.2.2:8080/api/orders";

  Future<Map<String, dynamic>> submitOrder(OrderRequest order, String token) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(order.toJson()),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data; // Berhasil
      } else {
        return {'error': data['error'] ?? 'Gagal membuat pesanan'};
      }
    } catch (e) {
      return {'error': 'Koneksi gagal: $e'};
    }
  }
}