import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';

// Palette Warna Premium (Organic & Luxury)
const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);
const Color colorDeepSageLight = Color(0xFFE8EEDF);

class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  String _searchQuery = '';
  late TabController _tabController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Auto load data saat screen dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProvider.notifier).loadProducts();
      ref.read(productProvider.notifier).loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _showCheckoutDialog() {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CheckoutDialog(
        total: cartState.total,
        onCheckout: (method) async {
          setState(() => _isProcessing = true);
          try {
            await ref.read(cartProvider.notifier).checkout(method);
            if (mounted) Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaksi Berhasil! ✨'), 
                backgroundColor: colorDeepSage,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.only(bottom: 110, left: 20, right: 20),
              ),
            );
          } catch (e) {
            if (mounted) Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
            );
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final productState = ref.watch(productProvider);
    final cartState = ref.watch(cartProvider);
    final isAdmin = authState.user?.isAdmin ?? false;

    if (isAdmin) return _buildAdminAccessBlocked();

    final filteredProducts = productState.products
        .where((p) => p.productName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: colorMilkWhite,
      body: Stack(
        children: [
          // 1. CONTENT AREA (UTAMA)
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeader(),
                _buildSearchAndFilter(),
                _buildSegmentedControl(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProductGrid(productState.isLoading, filteredProducts),
                      _buildCartList(cartState),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. FLOATING SUMMARY BAR (NAVIGASI POS)
          // POSISI DINAIKKAN ke 110 agar tidak tertutup Dock Dashboard (yang ada di 25)
          if (cartState.items.isNotEmpty)
            Positioned(
              bottom: 110, 
              left: 20,
              right: 20,
              child: _buildFloatingCheckoutBar(cartState),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("MENU", style: TextStyle(letterSpacing: 4, fontSize: 10, fontWeight: FontWeight.w400, color: Colors.grey)),
              Text("Katalog Produk", 
                style: TextStyle(color: colorDeepSage, fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ),
          IconButton(
            onPressed: () => ref.read(productProvider.notifier).loadProducts(),
            icon: const Icon(Icons.refresh_rounded, color: colorDeepSage),
            style: IconButton.styleFrom(backgroundColor: colorDeepSage.withOpacity(0.05)),
          )
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: colorDeepSage.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: "Cari menu atau produk...",
            hintStyle: TextStyle(color: colorDeepSage.withOpacity(0.3)),
            prefixIcon: const Icon(Icons.search_rounded, color: colorDeepSage),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
      height: 56, 
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorDeepSage.withOpacity(0.08), 
        borderRadius: BorderRadius.circular(18),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorDeepSage, 
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: colorDeepSage.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
          ]
        ),
        labelColor: Colors.white,
        unselectedLabelColor: colorDeepSage.withOpacity(0.6),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        dividerColor: Colors.transparent, 
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: "Etalase"), 
          Tab(text: "Keranjang")
        ],
      ),
    );
  }

  Widget _buildProductGrid(bool isLoading, List<dynamic> products) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: colorDeepSage));
    
    if (products.isEmpty) {
      return Center(child: Text("Produk tidak ditemukan", style: TextStyle(color: colorDeepSage.withOpacity(0.3))));
    }

    return GridView.builder(
      // Padding bawah 200px sangat penting agar item terakhir tidak tertutup 2 bar melayang
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 200), 
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, 
        crossAxisSpacing: 20, 
        mainAxisSpacing: 20, 
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _ProductCard(
          product: product,
          onTap: () {
            ref.read(cartProvider.notifier).addToCart(product);
            
            // Visual Feedback
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${product.productName} ditambahkan"),
                duration: const Duration(seconds: 1),
                backgroundColor: colorDeepSage,
                behavior: SnackBarBehavior.floating,
                width: 200,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartList(dynamic cartState) {
    if (cartState.items.isEmpty) {
      return Center(child: Text("Keranjang Kosong", style: TextStyle(color: colorDeepSage.withOpacity(0.3))));
    }
    return ListView.builder(
      // Padding bawah 200px sangat penting
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 200),
      itemCount: cartState.items.length,
      itemBuilder: (context, index) => _CartItemTile(item: cartState.items[index]),
    );
  }

  Widget _buildFloatingCheckoutBar(dynamic cartState) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorDeepSage,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colorDeepSage.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("TOTAL HARGA", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(_currencyFormat.format(cartState.total), 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 15),
          ElevatedButton(
            onPressed: _showCheckoutDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorMilkWhite,
              foregroundColor: colorDeepSage,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              elevation: 0,
            ),
            child: const Text("BAYAR", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          )
        ],
      ),
    );
  }

  Widget _buildAdminAccessBlocked() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_person_rounded, size: 64, color: colorDeepSage.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text("Akses POS Dibatasi untuk Admin", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ================= WIDGET COMPONENTS =================

class _ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final int stock = product.stock ?? 0;
    final bool outOfStock = stock <= 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque, 
      onTap: outOfStock ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: colorDeepSage.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorDeepSage.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  image: product.imageUrl != null && product.imageUrl != ""
                      ? DecorationImage(image: NetworkImage(product.imageUrl!), fit: BoxFit.cover)
                      : null,
                ),
                child: outOfStock 
                    ? Container(
                        decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                        child: const Center(child: Text("HABIS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                      ) 
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName ?? "No Name", 
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), 
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("Rp ${product.price}", style: const TextStyle(color: colorDeepSage, fontWeight: FontWeight.w900, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text("Stok: $stock", style: TextStyle(fontSize: 10, color: outOfStock ? Colors.red : Colors.grey)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final dynamic item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorDeepSage.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("Rp ${item.price}", style: TextStyle(color: colorDeepSage.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: colorDeepSage.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent), 
                  onPressed: () => ref.read(cartProvider.notifier).decreaseQuantity(item.productId)
                ),
                Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: colorDeepSage), 
                  onPressed: () => ref.read(cartProvider.notifier).increaseQuantity(item.productId)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _CheckoutDialog extends StatelessWidget {
  final double total;
  final Function(String) onCheckout;
  const _CheckoutDialog({required this.total, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return AlertDialog(
      backgroundColor: colorMilkWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: const Text("Metode Bayar", style: TextStyle(fontWeight: FontWeight.w900, color: colorDeepSage)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: colorDeepSage.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Tagihan", style: TextStyle(fontSize: 12)),
                Text(fmt.format(total), style: const TextStyle(fontWeight: FontWeight.bold, color: colorDeepSage)),
              ],
            ),
          ),
          _methodTile(context, "Tunai", Icons.payments_rounded, "cash"),
          const SizedBox(height: 10),
          _methodTile(context, "QRIS", Icons.qr_code_scanner_rounded, "qris"),
        ],
      ),
    );
  }

  Widget _methodTile(BuildContext context, String title, IconData icon, String value) {
    return InkWell(
      onTap: () => onCheckout(value),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: colorDeepSage.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorDeepSage),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}