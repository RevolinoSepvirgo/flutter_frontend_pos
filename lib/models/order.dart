class Order {
  final String? id;
  final String? nomorStruk;
  final String? namaToko;
  final List<OrderItem> items;
  final double subtotal;
  final double totalHarga;
  final String metodePembayaran;
  final double? bayar;
  final double? kembali;
  final DateTime? createdAt;

  Order({
    this.id,
    this.nomorStruk,
    this.namaToko,
    required this.items,
    required this.subtotal,
    required this.totalHarga,
    required this.metodePembayaran,
    this.bayar,
    this.kembali,
    this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['_id'] ?? json['id'],
      nomorStruk: json['nomorStruk'],
      namaToko: json['namaToko'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      subtotal: _toDouble(json['subtotal']),
      totalHarga: _toDouble(json['totalHarga']),
      metodePembayaran: json['metodePembayaran'],
      bayar: json['bayar'] != null ? _toDouble(json['bayar']) : null,
      kembali: json['kembali'] != null ? _toDouble(json['kembali']) : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': totalHarga,
      'totalHarga': totalHarga,
      'metodePembayaran': _mapPaymentMethod(metodePembayaran),
      if (bayar != null) 'bayar': bayar,
    };
  }

  // Helper untuk convert payment method
  static String _mapPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Tunai';
      case 'debit':
        return 'Debit';
      case 'qris':
        return 'QRIS';
      default:
        return 'Tunai';
    }
  }

  static double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class OrderItem {
  final String idProduk; // ✅ Ubah dari int ke String
  final String? namaProduk;
  final int qty;
  final double? harga;
  final double? total;

  OrderItem({
    required this.idProduk,
    this.namaProduk,
    required this.qty,
    this.harga,
    this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      idProduk: json['id_produk'].toString(),
      namaProduk: json['nama_produk'],
      qty: json['qty'] is int ? json['qty'] : int.parse(json['qty'].toString()),
      harga: json['harga'] != null ? Order._toDouble(json['harga']) : null,
      total: json['total'] != null ? Order._toDouble(json['total']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_produk': idProduk, // ✅ Format sesuai backend Java
      'qty': qty,            // ✅ Format sesuai backend Java
      if (namaProduk != null) 'nama_produk': namaProduk,
      if (harga != null) 'harga': harga,
      if (total != null) 'total': total,
    };
  }
}

class CartItem {
  final int productId;
  final String productName;
  final double price;
  final int quantity;
  final int stock;

  CartItem({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.stock,
  });

  double get subtotal => price * quantity;
  bool get canAddMore => quantity < stock;

  CartItem copyWith({
    int? productId,
    String? productName,
    double? price,
    int? quantity,
    int? stock,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      stock: stock ?? this.stock,
    );
  }
}