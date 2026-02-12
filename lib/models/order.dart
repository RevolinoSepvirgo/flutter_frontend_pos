// ============================================
// CART ITEM (Untuk keranjang di Flutter)
// ============================================
class CartItem {
  final int productId;
  final String productName;
  final double price;
  int quantity;
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

  // Konversi ke Map untuk dikirim ke Backend
  Map<String, dynamic> toBackendJson() {
    return {
      'id_produk': productId.toString(),
      'nama_produk': productName,
      'harga': price,
      'qty': quantity,
      'total': subtotal,
    };
  }

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

// ============================================
// ORDER REQUEST (Request ke Backend Java)
// ============================================
class OrderRequest {
  final String namaToko;
  final List<CartItem> items;
  final double subtotal;
  final double totalHarga;
  final String metodePembayaran;
  final double bayar;
  final double kembali;

  OrderRequest({
    required this.namaToko,
    required this.items,
    required this.subtotal,
    required this.totalHarga,
    required this.metodePembayaran,
    required this.bayar,
    required this.kembali,
  });

  Map<String, dynamic> toJson() {
    return {
      'namaToko': namaToko,
      'items': items.map((item) => item.toBackendJson()).toList(),
      'subtotal': subtotal,
      'totalHarga': totalHarga,
      'metodePembayaran': metodePembayaran,
      'bayar': bayar,
      'kembali': kembali,
    };
  }
}

// ============================================
// ORDER (Response dari Backend Java)
// ============================================
class Order {
  final String? id;
  final String? nomorStruk;
  final String namaToko;
  final List<OrderItem> items;
  final double? subtotal;
  final double totalHarga;
  final String metodePembayaran;
  final double? bayar;
  final double? kembali;
  final DateTime createdAt;

  Order({
    this.id,
    this.nomorStruk,
    required this.namaToko,
    required this.items,
    this.subtotal,
    required this.totalHarga,
    required this.metodePembayaran,
    this.bayar,
    this.kembali,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      nomorStruk: json['nomorStruk'],
      namaToko: json['namaToko'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      subtotal: _toDouble(json['subtotal']),
      totalHarga: _toDouble(json['totalHarga']) ?? 0,
      metodePembayaran: json['metodePembayaran'] ?? '',
      bayar: _toDouble(json['bayar']),
      kembali: _toDouble(json['kembali']),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return null;
  }

  // Getter untuk compatibility dengan UI
  String get paymentMethod => metodePembayaran;
  double get total => totalHarga;
}

// ============================================
// ORDER ITEM (Item dalam Order Response)
// ============================================
class OrderItem {
  final String idProduk;
  final String namaProduk;
  final double harga;
  final int qty;
  final double total;

  OrderItem({
    required this.idProduk,
    required this.namaProduk,
    required this.harga,
    required this.qty,
    required this.total,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      idProduk: json['id_produk']?.toString() ?? '',
      namaProduk: json['nama_produk']?.toString() ?? '',
      harga: _toDouble(json['harga']) ?? 0,
      qty: json['qty'] is int ? json['qty'] : int.tryParse(json['qty'].toString()) ?? 0,
      total: _toDouble(json['total']) ?? 0,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return 0;
  }

  // Untuk compatibility dengan UI yang expect productName & quantity
  String get productName => namaProduk;
  int get quantity => qty;
  double get price => harga;
  double get subtotal => total;
}