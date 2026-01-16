import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/order_service.dart';
import '../services/report_service.dart';
import 'auth_provider.dart';
import 'report_provider.dart';

class CartState {
  final List<CartItem> items;

  const CartState({this.items = const []});

  double get total => items.fold(0, (sum, item) => sum + item.subtotal);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends StateNotifier<CartState> {
  final Ref ref;
  final OrderService _orderService = OrderService();
  final ReportService _reportService = ReportService();

  CartNotifier(this.ref) : super(const CartState());

  void addToCart(Product product) {
    final index =
        state.items.indexWhere((item) => item.productId == product.id);

    if (index >= 0) {
      final updated = [...state.items];
      final existing = updated[index];

      if (existing.quantity < product.stock) {
        updated[index] =
            existing.copyWith(quantity: existing.quantity + 1);
        state = state.copyWith(items: updated);
      }
    } else {
      if (product.stock > 0) {
        state = state.copyWith(
          items: [
            ...state.items,
            CartItem(
              productId: product.id,
              productName: product.productName,
              price: product.price,
              quantity: 1,
              stock: product.stock,
            ),
          ],
        );
      }
    }
  }

  void increaseQuantity(int productId) {
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.productId == productId && item.canAddMore) {
          return item.copyWith(quantity: item.quantity + 1);
        }
        return item;
      }).toList(),
    );
  }

  void decreaseQuantity(int productId) {
    final updated = <CartItem>[];

    for (final item in state.items) {
      if (item.productId == productId) {
        if (item.quantity > 1) {
          updated.add(item.copyWith(quantity: item.quantity - 1));
        }
      } else {
        updated.add(item);
      }
    }

    state = state.copyWith(items: updated);
  }

  void clearCart() {
    state = const CartState();
  }

  Future<void> checkout(String paymentMethod, {double? cashAmount}) async {
    if (state.items.isEmpty) {
      throw Exception('Keranjang kosong');
    }

    final authState = ref.read(authProvider);
    final token = authState.token;
    final storeName = authState.user?.storeName;

    if (token == null || storeName == null) {
      throw Exception('Sesi login tidak valid');
    }

    try {
      final orderItems = state.items.map((item) {
        return OrderItem(
          idProduk: item.productId.toString(),
          namaProduk: item.productName,
          qty: item.quantity,
          harga: item.price,
          total: item.subtotal,
        );
      }).toList();

      final order = Order(
        namaToko: storeName,
        items: orderItems,
        subtotal: state.total,
        totalHarga: state.total,
        metodePembayaran: paymentMethod,
        bayar: cashAmount,
        createdAt: DateTime.now(),
      );

      // ✅ 1️⃣ Create order
      await _orderService.createOrder(token: token, order: order);

      // ✅ 2️⃣ Refresh report dashboard UI
      ref.read(reportProvider.notifier).loadDashboard();

      // ✅ 3️⃣ Clear cart
      state = const CartState();
    } catch (e) {
      throw Exception('Checkout gagal: $e');
    }
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier(ref);
});
