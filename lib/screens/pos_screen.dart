import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';

/* ==================== THEME COLORS ==================== */
const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);
const Color colorGold = Color(0xFFC5A358);

class POSScreen extends ConsumerStatefulWidget {
  const POSScreen({super.key});

  @override
  ConsumerState<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends ConsumerState<POSScreen> {
  final _searchController = TextEditingController();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool _isGlobalLoading = false; // Untuk overlay layar utama jika diperlukan

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(productProvider.notifier).loadProducts());
  }

  void _showCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CartBottomSheet(
        currency: _currency,
        onCheckout: _handleCheckout,
      ),
    );
  }

  void _handleCheckout() {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CheckoutDialog(
        total: cartState.total,
        currency: _currency,
        // Kita tangani proses async di dalam dialog agar tombol bisa menunjukkan loading
        onConfirm: (method, amount) async {
          try {
            await ref.read(cartProvider.notifier).checkout(method, bayar: amount);
            if (mounted) {
              Navigator.pop(context); // Tutup Dialog
              ref.read(productProvider.notifier).loadProducts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaksi Berhasil! ✨'), 
                  backgroundColor: colorDeepSage,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            // Error ditangani di level dialog (rethrow agar dialog tahu proses gagal)
            rethrow;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final cartState = ref.watch(cartProvider);

    final categories = ['Semua', ...productState.products.map((p) => p.categoryName ?? 'Lainnya').toSet()];

    final filteredProducts = productState.products.where((p) {
      final matchesSearch = p.productName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Semua' || p.categoryName == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: colorMilkWhite,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                _buildSearchField(),
                _buildCategoryFilter(categories.toList()),
                Expanded(
                  child: _buildProductGrid(productState.isLoading, filteredProducts),
                ),
              ],
            ),
          ),
          
          if (cartState.total > 0) 
            _buildStickyCartBar(cartState),

          if (_isGlobalLoading)
            const Center(child: CircularProgressIndicator(color: colorDeepSage)),
        ],
      ),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Dashboard Kasir", style: TextStyle(color: colorDeepSage, fontSize: 24, fontWeight: FontWeight.bold)),
            Text("Kelola pesanan dengan mudah", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        IconButton(
          onPressed: () => ref.read(productProvider.notifier).loadProducts(),
          icon: const Icon(Icons.refresh_rounded, color: colorDeepSage),
        ),
      ],
    ),
  );

  Widget _buildSearchField() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(
          hintText: "Cari produk kasir...",
          prefixIcon: Icon(Icons.search_rounded, color: colorDeepSage),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    ),
  );

  Widget _buildCategoryFilter(List<String> categories) => Container(
    height: 50,
    margin: const EdgeInsets.symmetric(vertical: 10),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategory == category;
        return Padding(
          padding: const EdgeInsets.only(right: 10),
          child: ChoiceChip(
            label: Text(category),
            selected: isSelected,
            onSelected: (val) => setState(() => _selectedCategory = category),
            selectedColor: colorDeepSage,
            labelStyle: TextStyle(color: isSelected ? Colors.white : colorDeepSage, fontWeight: FontWeight.bold),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: BorderSide(color: isSelected ? colorDeepSage : colorDeepSage.withOpacity(0.2)),
          ),
        );
      },
    ),
  );

  Widget _buildProductGrid(bool isLoading, List products) {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: colorDeepSage));
    if (products.isEmpty) return const Center(child: Text("Tidak ada produk"));
    
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 120),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.78
      ),
      itemCount: products.length,
      itemBuilder: (context, i) => _ProductCard(
        product: products[i],
        currency: _currency,
        onAdd: () {
          ref.read(cartProvider.notifier).addToCart(products[i]);
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
              content: Text('${products[i].productName} ditambahkan'), 
              duration: const Duration(milliseconds: 500),
              behavior: SnackBarBehavior.floating,
              width: 200,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStickyCartBar(dynamic cartState) => Align(
    alignment: Alignment.bottomCenter,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: InkWell(
        onTap: _showCartBottomSheet,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: colorDeepSage,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: colorDeepSage.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_bag_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Text("${cartState.items.length} Barang", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              Row(
                children: [
                  Text(_currency.format(cartState.total), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CartBottomSheet extends ConsumerWidget {
  final NumberFormat currency;
  final VoidCallback onCheckout;
  const _CartBottomSheet({required this.currency, required this.onCheckout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 25),
          const Text("Ringkasan Belanja", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorDeepSage)),
          const Divider(height: 30),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cartState.items.length,
              itemBuilder: (context, i) {
                final item = cartState.items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(currency.format(item.price), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => ref.read(cartProvider.notifier).decreaseQuantity(item.productId), 
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent)
                          ),
                          Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          IconButton(
                            onPressed: () => ref.read(cartProvider.notifier).increaseQuantity(item.productId), 
                            icon: const Icon(Icons.add_circle_outline, color: colorDeepSage)
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 30),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Tagihan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text(currency.format(cartState.total), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorGold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: cartState.items.isEmpty ? null : () {
              Navigator.pop(context);
              onCheckout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorDeepSage,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 0,
            ),
            child: const Text("LANJUT PEMBAYARAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  final NumberFormat currency;
  final VoidCallback onAdd;
  const _ProductCard({required this.product, required this.currency, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final bool outOfStock = (product.stock ?? 0) < 1;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorDeepSage.withOpacity(0.05), 
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.restaurant_menu_rounded, color: colorDeepSage, size: 45),
                  if (outOfStock)
                    Container(
                      decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(20)),
                      child: const Center(child: Text("HABIS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(currency.format(product.price), style: const TextStyle(color: colorGold, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Stok: ${product.stock}", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    InkWell(
                      onTap: outOfStock ? null : onAdd,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: outOfStock ? Colors.grey : colorDeepSage, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutDialog extends StatefulWidget {
  final double total;
  final NumberFormat currency;
  final Future<void> Function(String, double) onConfirm;

  const _CheckoutDialog({required this.total, required this.currency, required this.onConfirm});

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final _payController = TextEditingController();
  double _kembalian = 0;
  bool _isProcessing = false;

  void _calculateKembalian(String value) {
    double input = double.tryParse(value) ?? 0;
    setState(() {
      _kembalian = input - widget.total;
    });
  }

  Future<void> _handleAction(String method, double amount) async {
    setState(() => _isProcessing = true);
    try {
      await widget.onConfirm(method, amount);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: colorMilkWhite,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Konfirmasi Pembayaran", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorDeepSage)),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(color: colorDeepSage, borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  const Text("Total Tagihan", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(widget.currency.format(widget.total), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _payController,
              keyboardType: TextInputType.number,
              onChanged: _calculateKembalian,
              enabled: !_isProcessing,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: colorDeepSage),
              decoration: InputDecoration(
                labelText: "Uang yang Diterima",
                prefixText: "Rp ",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 8,
              children: [
                _quickActionChip("Uang Pas", widget.total),
                _quickActionChip("50.000", 50000),
                _quickActionChip("100.000", 100000),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Kembalian", style: TextStyle(color: Colors.grey)),
                Text(widget.currency.format(_kembalian < 0 ? 0 : _kembalian), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorDeepSage)),
              ],
            ),
            const SizedBox(height: 25),
            if (_isProcessing)
              const CircularProgressIndicator(color: colorDeepSage)
            else
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _kembalian < 0 ? null : () => _handleAction("cash", double.tryParse(_payController.text) ?? widget.total),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorDeepSage,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: const Column(children: [Icon(Icons.payments_outlined), Text("TUNAI", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handleAction("qris", widget.total),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: colorDeepSage, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Column(children: [Icon(Icons.qr_code_scanner, color: colorDeepSage), Text("QRIS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorDeepSage))]),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            if (!_isProcessing)
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }

  Widget _quickActionChip(String label, double value) {
    return ActionChip(
      label: Text(label),
      onPressed: _isProcessing ? null : () {
        _payController.text = value.toInt().toString();
        _calculateKembalian(_payController.text);
      },
    );
  }
}