import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart'; // Untuk ambil token JWT

// 1. MODEL ITEM KERANJANG
class CartItem {
  final String productId;
  final String productName;
  final double price;
  int quantity;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    this.quantity = 1,
  });

  // Sesuaikan dengan Map di Java (id_produk, nama_produk, harga, qty)
  Map<String, dynamic> toJson() {
    return {
      'id_produk': productId,
      'nama_produk': productName,
      'harga': price,
      'qty': quantity,
      'total': price * quantity,
    };
  }
}

// 2. STATE UNTUK RIVERPOD
class CartState {
  final List<CartItem> items;
  CartState({this.items = const []});

  double get total => items.fold(0, (sum, item) => sum + (item.price * item.quantity));
}

// 3. PROVIDER GLOBAL (HURUF KECIL)
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});

// 4. LOGIKA KERANJANG & CHECKOUT
class CartNotifier extends StateNotifier<CartState> {
  final Ref ref;
  CartNotifier(this.ref) : super(CartState());

  void addToCart(dynamic product) {
    // Pastikan 'product.id' sesuai dengan field di Product model Anda
    final productId = product.id.toString();
    final existingIndex = state.items.indexWhere((item) => item.productId == productId);
    
    if (existingIndex >= 0) {
      state.items[existingIndex].quantity++;
      state = CartState(items: [...state.items]);
    } else {
      state = CartState(items: [
        ...state.items,
        CartItem(
          productId: productId,
          productName: product.productName,
          price: product.price.toDouble(),
        )
      ]);
    }
  }

  void increaseQuantity(String id) {
    state = CartState(items: [
      for (final item in state.items)
        if (item.productId == id)
          CartItem(productId: item.productId, productName: item.productName, price: item.price, quantity: item.quantity + 1)
        else
          item
    ]);
  }

  void decreaseQuantity(String id) {
    final List<CartItem> newList = [];
    for (final item in state.items) {
      if (item.productId == id) {
        if (item.quantity > 1) {
          newList.add(CartItem(productId: item.productId, productName: item.productName, price: item.price, quantity: item.quantity - 1));
        }
      } else {
        newList.add(item);
      }
    }
    state = CartState(items: newList);
  }

  void clearCart() => state = CartState(items: []);

  // FUNGSI SIMPAN KE DATABASE (BACKEND SPRING BOOT)
  Future<void> checkout(String method, {double? bayar}) async {
    final token = ref.read(authProvider).token; 
    // Ganti 10.0.2.2 dengan IP laptop Anda jika pakai HP fisik
    final url = Uri.parse("http://10.0.2.2:8080/api/orders"); 

    final body = {
      "items": state.items.map((e) => e.toJson()).toList(),
      "metodePembayaran": method == "cash" ? "Tunai" : "QRIS",
      "bayar": method == "cash" ? (bayar ?? state.total) : state.total,
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      clearCart();
    } else {
      final errorData = jsonDecode(response.body);
      throw errorData['error'] ?? "Gagal menyimpan transaksi";
    }
  }
}