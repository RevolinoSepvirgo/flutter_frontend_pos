import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../services/product_service.dart';
import 'auth_provider.dart';

// Product State
class ProductState {
  final List<Product> products;
  final List<Category> categories;
  final bool isLoading;
  final String? error;

  ProductState({
    this.products = const [],
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  ProductState copyWith({
    List<Product>? products,
    List<Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return ProductState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Product Provider
class ProductNotifier extends StateNotifier<ProductState> {
  final ProductService _productService = ProductService();
  final String? token;

  ProductNotifier(this.token) : super(ProductState()) {
    if (token != null) {
      loadProducts();
      loadCategories();
    }
  }

  // Load Products
  // Load Products
Future<void> loadProducts({bool forceRefresh = false}) async {
  if (token == null) {
    print('❌ TOKEN NULL - Tidak bisa load products');
    return;
  }

  print('🔄 Loading products... Token: ${token!.substring(0, 20)}...');
  
  // ✅ FORCE REFRESH: Clear cache dulu
  if (forceRefresh) {
    print('🔄 FORCE REFRESH - Clearing local cache first');
    state = state.copyWith(products: [], isLoading: true, error: null);
  } else {
    state = state.copyWith(isLoading: true, error: null);
  }

  try {
    final products = await _productService.getAllProducts(token!);
    print('✅ Products loaded: ${products.length} items');
    if (products.isNotEmpty) {
      print('📦 First product: ${products[0].productName} - Stock: ${products[0].stock}');
    }
    state = state.copyWith(products: products, isLoading: false);
  } catch (e) {
    print('❌ ERROR loading products: $e');
    state = state.copyWith(
      isLoading: false,
      error: e.toString().replaceAll('Exception: ', ''),
    );
  }
}
  // Load Categories
  Future<void> loadCategories() async {
    if (token == null) {
      print('❌ TOKEN NULL - Tidak bisa load categories');
      return;
    }

    print('🔄 Loading categories...');
    try {
      final categories = await _productService.getAllCategories(token!);
      print('✅ Categories loaded: ${categories.length} items');
      state = state.copyWith(categories: categories);
    } catch (e) {
      print('❌ ERROR loading categories: $e');
      // Ignore category load error
    }
  }

  // Create Product
  Future<void> createProduct({
    required int categoryId,
    required String productName,
    required double price,
    required int stock,
    String? imageUrl,
  }) async {
    if (token == null) return;

    try {
      await _productService.createProduct(
        token: token!,
        categoryId: categoryId,
        productName: productName,
        price: price,
        stock: stock,
        imageUrl: imageUrl,
      );
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  // Update Product
  Future<void> updateProduct({
    required int productId,
    required int categoryId,
    required String productName,
    required double price,
    required int stock,
    String? imageUrl,
  }) async {
    if (token == null) return;

    try {
      await _productService.updateProduct(
        token: token!,
        productId: productId,
        categoryId: categoryId,
        productName: productName,
        price: price,
        stock: stock,
        imageUrl: imageUrl,
      );
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  // Delete Product
  Future<void> deleteProduct(int productId) async {
    if (token == null) return;

    try {
      await _productService.deleteProduct(token!, productId);
      await loadProducts();
    } catch (e) {
      rethrow;
    }
  }

  // Create Category
  Future<void> createCategory(String categoryName) async {
    if (token == null) return;

    try {
      await _productService.createCategory(
        token: token!,
        categoryName: categoryName,
      );
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  // Update Category
  Future<void> updateCategory(int categoryId, String categoryName) async {
    if (token == null) return;

    try {
      await _productService.updateCategory(
        token: token!,
        categoryId: categoryId,
        categoryName: categoryName,
      );
      await loadCategories();
    } catch (e) {
      rethrow;
    }
  }

  // Delete Category
  Future<void> deleteCategory(int categoryId) async {
    if (token == null) return;

    try {
      await _productService.deleteCategory(token!, categoryId);
      await loadCategories();
      await loadProducts(); // Reload products karena mungkin terpengaruh
    } catch (e) {
      rethrow;
    }
  }

  // Search Products
  List<Product> searchProducts(String query) {
    if (query.isEmpty) return state.products;

    return state.products
        .where((product) =>
            product.productName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Filter by Category
  List<Product> filterByCategory(int categoryId) {
    return state.products
        .where((product) => product.categoryId == categoryId)
        .toList();
  }
}

// Provider instance
final productProvider =
    StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final token = ref.watch(authProvider).token;
  return ProductNotifier(token);
});