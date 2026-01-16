class Product {
  final int id;
  final String storeName;
  final int categoryId;
  final String productName;
  final double price;
  final int stock;
  final String? categoryName;
  final String? imageUrl;

  Product({
    required this.id,
    required this.storeName,
    required this.categoryId,
    required this.productName,
    required this.price,
    required this.stock,
    this.categoryName,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      storeName: json['nama_toko'],
      categoryId: json['category_id'],
      productName: json['nama_produk'],
      price: (json['harga'] is int) 
          ? (json['harga'] as int).toDouble() 
          : json['harga'],
      stock: json['stok'],
      categoryName: json['nama_kategori'],
      imageUrl: json['gambar_produk'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'nama_produk': productName,
      'harga': price,
      'stok': stock,
      'gambar_produk': imageUrl,
    };
  }

  // Helper methods
  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= 10;
  
  Product copyWith({
    int? id,
    String? storeName,
    int? categoryId,
    String? productName,
    double? price,
    int? stock,
    String? categoryName,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      storeName: storeName ?? this.storeName,
      categoryId: categoryId ?? this.categoryId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}