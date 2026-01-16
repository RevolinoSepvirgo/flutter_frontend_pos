import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart'; 
import '../providers/auth_provider.dart';

const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProvider.notifier).loadProducts();
    });
  }

  void _showCheckoutDialog() {
    // FIX: Gunakan cartProvider (huruf kecil), bukan CartProvider()
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CheckoutDialog(
        total: cartState.total,
        onCheckout: (method, uangBayar) async {
          setState(() => _isProcessing = true);
          try {
            await ref.read(cartProvider.notifier).checkout(method, bayar: uangBayar);
            if (mounted) {
              Navigator.pop(context);
              ref.read(productProvider.notifier).loadProducts(); // Refresh Stok
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaksi Berhasil! ✨'), backgroundColor: colorDeepSage),
              );
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
              );
            }
          } finally {
            if (mounted) setState(() => _isProcessing = false);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final cartState = ref.watch(cartProvider);

    final filteredProducts = productState.products
        .where((p) => p.productName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: colorMilkWhite,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildSearch(),
                _buildTabs(),
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
          if (cartState.items.isNotEmpty)
            Positioned(bottom: 110, left: 20, right: 20, child: _buildFloatingBar(cartState)),
          if (_isProcessing) 
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.all(25),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Katalog Produk", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorDeepSage)),
        IconButton(onPressed: () => ref.read(productProvider.notifier).loadProducts(), icon: const Icon(Icons.refresh)),
      ],
    ),
  );

  Widget _buildSearch() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: TextField(
      controller: _searchController, 
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(hintText: "Cari...", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
    ),
  );

  Widget _buildTabs() => Container(
    margin: const EdgeInsets.all(16),
    height: 50,
    decoration: BoxDecoration(color: colorDeepSage.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
    child: TabBar(
      controller: _tabController,
      indicator: BoxDecoration(color: colorDeepSage, borderRadius: BorderRadius.circular(12)),
      labelColor: Colors.white, unselectedLabelColor: colorDeepSage,
      tabs: const [Tab(text: "Etalase"), Tab(text: "Keranjang")],
    ),
  );

  Widget _buildProductGrid(bool isLoading, List products) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 200),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.75),
      itemCount: products.length,
      itemBuilder: (context, i) => _ProductCard(
        product: products[i], 
        onTap: () => ref.read(cartProvider.notifier).addToCart(products[i]),
      ),
    );
  }

  Widget _buildCartList(dynamic cartState) {
    if (cartState.items.isEmpty) return const Center(child: Text("Kosong"));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 200),
      itemCount: cartState.items.length,
      itemBuilder: (context, i) => _CartItemTile(item: cartState.items[i]),
    );
  }

  Widget _buildFloatingBar(dynamic cartState) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: colorDeepSage, borderRadius: BorderRadius.circular(20)),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("TOTAL", style: TextStyle(color: Colors.white70, fontSize: 10)),
          Text(_currencyFormat.format(cartState.total), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        ElevatedButton(onPressed: _showCheckoutDialog, child: const Text("BAYAR")),
      ],
    ),
  );
}

// --- SUB-WIDGETS ---
class _ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final stock = product.stock ?? 0;
    return GestureDetector(
      onTap: stock > 0 ? onTap : null,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          Expanded(child: Container(color: colorDeepSage.withOpacity(0.05))),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(children: [
              Text(product.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("Rp ${product.price}"),
              Text("Stok: $stock", style: TextStyle(color: stock < 1 ? Colors.red : Colors.grey, fontSize: 10)),
            ]),
          )
        ]),
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final dynamic item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: Text(item.productName),
      subtitle: Text("Rp ${item.price}"),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(icon: const Icon(Icons.remove_circle), onPressed: () => ref.read(cartProvider.notifier).decreaseQuantity(item.productId)),
        Text("${item.quantity}"),
        IconButton(icon: const Icon(Icons.add_circle), onPressed: () => ref.read(cartProvider.notifier).increaseQuantity(item.productId)),
      ]),
    );
  }
}

class _CheckoutDialog extends StatefulWidget {
  final double total;
  final Function(String, double) onCheckout;
  const _CheckoutDialog({required this.total, required this.onCheckout});

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final _payController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Pembayaran"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("Total: Rp ${widget.total}"),
        const SizedBox(height: 10),
        TextField(controller: _payController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Uang Bayar", prefixText: "Rp ")),
        const SizedBox(height: 15),
        ElevatedButton(onPressed: () => widget.onCheckout("cash", double.tryParse(_payController.text) ?? widget.total), child: const Text("Tunai")),
        TextButton(onPressed: () => widget.onCheckout("qris", widget.total), child: const Text("QRIS")),
      ]),
    );
  }
}