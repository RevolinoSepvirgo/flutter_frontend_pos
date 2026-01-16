class Category {
  final int id;
  final String storeName;
  final String categoryName;

  Category({
    required this.id,
    required this.storeName,
    required this.categoryName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      storeName: json['nama_toko'],
      categoryName: json['nama_kategori'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama_kategori': categoryName,
    };
  }
}