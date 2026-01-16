import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/product_provider.dart';

// Palette Warna Premium
const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showProductForm({dynamic product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ProductFormDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final filteredProducts = _searchQuery.isEmpty
        ? productState.products
        : productState.products
            .where((p) => p.productName.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      backgroundColor: colorMilkWhite,
      // Hapus FAB dari sini karena dipindah ke Header agar tidak tertutup dock
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER DENGAN TOMBOL TAMBAH
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("INVENTORY", 
                      style: TextStyle(letterSpacing: 4, fontSize: 12, fontWeight: FontWeight.w300)),
                    Text("Daftar Produk", 
                      style: TextStyle(color: colorDeepSage, fontSize: 28, fontWeight: FontWeight.w900)),
                  ],
                ),
                // TOMBOL TAMBAH DI SINI (Lebih Pro & Tidak Tertutup)
                GestureDetector(
                  onTap: () => _showProductForm(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorDeepSage,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: colorDeepSage.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),

          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: colorDeepSage.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Cari inventori...',
                  hintStyle: TextStyle(color: colorDeepSage.withOpacity(0.3)),
                  prefixIcon: const Icon(Icons.search_rounded, color: colorDeepSage),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),

          // PRODUCT LIST
          Expanded(
            child: productState.isLoading
                ? const Center(child: CircularProgressIndicator(color: colorDeepSage))
                : filteredProducts.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        // PENTING: Beri padding bawah yang besar (120-150) agar item terakhir tidak tertutup dock navigasi
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 130), 
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildProductCard(product, currencyFormat);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(dynamic product, NumberFormat fmt) {
    bool lowStock = product.stock < 5;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: colorDeepSage.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 85,
              height: 85,
              decoration: BoxDecoration(
                color: colorDeepSage.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(product.imageUrl!, fit: BoxFit.cover, 
                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_rounded, color: colorDeepSage))
                    : const Icon(Icons.inventory_2_rounded, color: colorDeepSage, size: 30),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName, 
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(product.categoryName ?? 'Umum', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(fmt.format(product.price), 
                    style: const TextStyle(color: colorDeepSage, fontWeight: FontWeight.w900, fontSize: 15)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: lowStock ? Colors.red[50] : colorDeepSage.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Stok: ${product.stock}',
                    style: TextStyle(color: lowStock ? Colors.red : colorDeepSage, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _circleAction(Icons.edit_rounded, Colors.blue[400]!, () => _showProductForm(product: product)),
                    const SizedBox(width: 8),
                    _circleAction(Icons.delete_outline_rounded, Colors.red[300]!, () => _confirmDelete(product)),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _circleAction(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 60, color: colorDeepSage.withOpacity(0.1)),
          const SizedBox(height: 10),
          const Text("Produk tidak ditemukan", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDelete(dynamic product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorMilkWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Produk?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Hapus ${product.productName} dari sistem?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(productProvider.notifier).deleteProduct(product.id);
    }
  }
}

// ... Form Dialog Tetap Sama Seperti Sebelumnya ...

// ---------------------------------------------------------
// FORM DIALOG MENGGUNAKAN BOTTOM SHEET AGAR LEBIH KREATIF
// ---------------------------------------------------------
class _ProductFormDialog extends ConsumerStatefulWidget {
  final dynamic product;
  const _ProductFormDialog({this.product});

  @override
  ConsumerState<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends ConsumerState<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _imageUrlController;
  int? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.productName ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');
    _imageUrlController = TextEditingController(text: widget.product?.imageUrl ?? '');
    _selectedCategoryId = widget.product?.categoryId;
    _imageUrlController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(productProvider).categories;

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: colorMilkWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 20),
              Text(widget.product == null ? 'Tambah Produk Baru' : 'Perbarui Produk', 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorDeepSage)),
              const SizedBox(height: 25),
              
              _customInput("Nama Produk", _nameController, Icons.label_important_outline),
              const SizedBox(height: 15),
              
              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: _inputDecoration("Kategori", Icons.category_outlined),
                items: categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.categoryName))).toList(),
                onChanged: (v) => setState(() => _selectedCategoryId = v),
              ),
              const SizedBox(height: 15),
              
              Row(
                children: [
                  Expanded(child: _customInput("Harga", _priceController, Icons.payments_outlined, isNumber: true)),
                  const SizedBox(width: 15),
                  Expanded(child: _customInput("Stok", _stockController, Icons.inventory_2_outlined, isNumber: true)),
                ],
              ),
              const SizedBox(height: 15),
              
              _customInput("URL Gambar", _imageUrlController, Icons.link_rounded),
              
              if (_imageUrlController.text.isNotEmpty) ...[
                const SizedBox(height: 20),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(_imageUrlController.text, height: 120, width: double.infinity, fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => const SizedBox()),
                  ),
                )
              ],
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: colorDeepSage, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.product == null ? 'Simpan Produk' : 'Simpan Perubahan', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customInput(String label, TextEditingController ctrl, IconData icon, {bool isNumber = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: _inputDecoration(label, icon),
      validator: (v) => v?.isEmpty ?? true ? 'Wajib diisi' : null,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colorDeepSage),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) return;
    setState(() => _isLoading = true);
    
    try {
      if (widget.product == null) {
        await ref.read(productProvider.notifier).createProduct(
          categoryId: _selectedCategoryId!,
          productName: _nameController.text,
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          imageUrl: _imageUrlController.text.trim(),
        );
      } else {
        await ref.read(productProvider.notifier).updateProduct(
          productId: widget.product.id,
          categoryId: _selectedCategoryId!,
          productName: _nameController.text,
          price: double.parse(_priceController.text),
          stock: int.parse(_stockController.text),
          imageUrl: _imageUrlController.text.trim(),
        );
      }
      Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }
}