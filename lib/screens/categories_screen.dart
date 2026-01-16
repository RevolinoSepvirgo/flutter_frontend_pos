import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';

// Palette Warna Premium (Konsisten)
const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);
const Color colorDeepSageLight = Color(0xFFE8EEDF);

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _showCategoryForm(BuildContext context, WidgetRef ref, {dynamic category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategoryFormDialog(category: category),
    );
  }

  Future<void> _deleteCategory(BuildContext context, WidgetRef ref, int categoryId, String categoryName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorMilkWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Kategori', style: TextStyle(fontWeight: FontWeight.w900, color: colorDeepSage)),
        content: Text('Yakin ingin menghapus "$categoryName"?\n\nProduk dengan kategori ini akan kehilangan relasinya.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(productProvider.notifier).deleteCategory(categoryId);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: colorMilkWhite,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER MODERN
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("COLLECTION", 
                      style: TextStyle(letterSpacing: 4, fontSize: 12, fontWeight: FontWeight.w300)),
                    Text("Kategori", 
                      style: TextStyle(color: colorDeepSage, fontSize: 28, fontWeight: FontWeight.w900)),
                  ],
                ),
                // Tombol Tambah di Atas (Agar tidak tertutup dock navigasi)
                GestureDetector(
                  onTap: () => _showCategoryForm(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorDeepSage,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: colorDeepSage.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // LIST KATEGORI
          Expanded(
            child: productState.isLoading
                ? const Center(child: CircularProgressIndicator(color: colorDeepSage))
                : productState.categories.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        // Padding bawah ekstra 130 agar tidak tertutup dock dashboard
                        padding: const EdgeInsets.fromLTRB(25, 10, 25, 130),
                        itemCount: productState.categories.length,
                        itemBuilder: (context, index) {
                          final category = productState.categories[index];
                          final productCount = productState.products
                              .where((p) => p.categoryId == category.id)
                              .length;

                          return _buildCategoryCard(context, ref, category, productCount);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, WidgetRef ref, dynamic category, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: colorDeepSage.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorDeepSage.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.grid_view_rounded, color: colorDeepSage),
        ),
        title: Text(
          category.categoryName,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colorDeepSage),
        ),
        subtitle: Text('$count Item Produk', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _circleAction(Icons.edit_rounded, Colors.blue[400]!, 
              () => _showCategoryForm(context, ref, category: category)),
            const SizedBox(width: 8),
            _circleAction(Icons.delete_outline_rounded, Colors.red[300]!, 
              () => _deleteCategory(context, ref, category.id, category.categoryName)),
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
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 60, color: colorDeepSage.withOpacity(0.1)),
          const SizedBox(height: 10),
          const Text("Belum ada kategori", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// FORM DIALOG MENGGUNAKAN MODAL BOTTOM SHEET (BOUTIQUE STYLE)
// ---------------------------------------------------------
class _CategoryFormDialog extends ConsumerStatefulWidget {
  final dynamic category;
  const _CategoryFormDialog({this.category});

  @override
  ConsumerState<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.categoryName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (widget.category == null) {
        await ref.read(productProvider.notifier).createCategory(_nameController.text);
      } else {
        await ref.read(productProvider.notifier).updateCategory(widget.category.id, _nameController.text);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
              Text(widget.category == null ? 'Tambah Kategori' : 'Edit Kategori', 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorDeepSage)),
              const SizedBox(height: 25),
              
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Nama Kategori",
                  prefixIcon: const Icon(Icons.label_outline_rounded, color: colorDeepSage),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
                validator: (v) => v?.isEmpty ?? true ? 'Nama kategori wajib diisi' : null,
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorDeepSage,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.category == null ? 'Simpan Kategori' : 'Perbarui Kategori', 
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}