import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/order.dart';

class OrderService {
  // Create Order (Checkout)
  Future<void> createOrder({
    required String token,
    required Order order,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.orderServiceUrl}/api/orders'),
        headers: ApiConfig.headers(token: token),
        body: jsonEncode(order.toJson()),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Gagal menyimpan transaksi');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }

  // Get All Orders
  Future<List<Order>> getAllOrders(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.orderServiceUrl}/api/orders'),
        headers: ApiConfig.headers(token: token),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        throw Exception('Gagal mengambil data transaksi');
      }
    } catch (e) {
      throw Exception('Tidak dapat terhubung ke server: $e');
    }
  }
}