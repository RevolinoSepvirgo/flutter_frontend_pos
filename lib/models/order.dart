// cart_model.dart
class CartItem {
  final String idProduk;
  final String namaProduk;
  final double harga;
  int qty;

  CartItem({
    required this.idProduk,
    required this.namaProduk,
    required this.harga,
    this.qty = 1,
  });

  // Konversi ke Map untuk dikirim ke Backend sesuai format List<Map<String, Object>>
  Map<String, dynamic> toJson() {
    return {
      'id_produk': idProduk,
      'nama_produk': namaProduk,
      'harga': harga,
      'qty': qty,
      'total': harga * qty,
    };
  }
}

// order_model.dart
class OrderRequest {
  final List<CartItem> items;
  final String metodePembayaran;
  final double bayar;

  OrderRequest({
    required this.items,
    required this.metodePembayaran,
    required this.bayar,
  });

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'metodePembayaran': metodePembayaran,
      'bayar': bayar,
    };
  }
}