import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

// Palette Warna Premium (Konsisten dengan Dashboard)
const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);

// Provider untuk mengambil data user dari API
final usersProvider = FutureProvider<List<User>>((ref) async {
  final token = ref.watch(authProvider).token;
  if (token == null) return [];
  
  final authService = AuthService();
  return await authService.getAllUsers(token);
});

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  // --- 1. POPUP DETAIL PENGGUNA ---
  void _showUserDetail(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => _UserDetailPopup(user: user),
    );
  }

  // --- 2. BOTTOM SHEET FORM (TAMBAH/EDIT) ---
  void _showUserForm(BuildContext context, WidgetRef ref, {User? user}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserFormDialog(user: user),
    );
  }

  // --- 3. LOGIKA HAPUS USER ---
  Future<void> _deleteUser(BuildContext context, WidgetRef ref, int userId, String username) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorMilkWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Hapus Akun', style: TextStyle(fontWeight: FontWeight.w900, color: colorDeepSage)),
        content: Text('Apakah Anda yakin ingin menghapus akses untuk "$username"?'),
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
        final token = ref.read(authProvider).token!;
        final authService = AuthService();
        await authService.deleteUser(token, userId);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User berhasil dihapus'), backgroundColor: colorDeepSage),
          );
          ref.invalidate(usersProvider); // Refresh list
        }
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
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: colorMilkWhite,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("ACCOUNTS", 
                      style: TextStyle(letterSpacing: 4, fontSize: 12, fontWeight: FontWeight.w300)),
                    Text("Pengguna", 
                      style: TextStyle(color: colorDeepSage, fontSize: 28, fontWeight: FontWeight.w900)),
                  ],
                ),
                GestureDetector(
                  onTap: () => _showUserForm(context, ref),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorDeepSage,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: colorDeepSage.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                      ],
                    ),
                    child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
                  ),
                ),
              ],
            ),
          ),

          // LIST USER
          Expanded(
            child: usersAsync.when(
              data: (users) => users.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(25, 10, 25, 130),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildUserCard(context, ref, user);
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator(color: colorDeepSage)),
              error: (err, stack) => Center(child: Text('Gagal memuat data: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, WidgetRef ref, User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: colorDeepSage.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => _showUserDetail(context, user), // Trigger popup detail
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: user.isAdmin ? Colors.red[50] : colorDeepSage.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.username[0].toUpperCase(),
                    style: TextStyle(
                      color: user.isAdmin ? Colors.red : colorDeepSage,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: user.isAdmin ? Colors.red[400] : colorDeepSage,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user.displayRole.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(user.storeName, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  _circleAction(Icons.edit_rounded, Colors.blue[400]!, 
                    () => _showUserForm(context, ref, user: user)),
                  const SizedBox(height: 10),
                  _circleAction(Icons.delete_outline_rounded, Colors.red[300]!, 
                    () => _deleteUser(context, ref, user.id, user.username)),
                ],
              )
            ],
          ),
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
          Icon(Icons.people_outline_rounded, size: 60, color: colorDeepSage.withOpacity(0.1)),
          const SizedBox(height: 10),
          const Text("Belum ada akun terdaftar", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------
// WIDGET POPUP DETAIL PENGGUNA
// ---------------------------------------------------------
class _UserDetailPopup extends StatelessWidget {
  final User user;
  const _UserDetailPopup({required this.user});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: colorMilkWhite,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar Besar
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: user.isAdmin ? Colors.red[50] : colorDeepSage.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.username[0].toUpperCase(),
                  style: TextStyle(
                    color: user.isAdmin ? Colors.red : colorDeepSage,
                    fontSize: 32, fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(user.username, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorDeepSage)),
            Text(user.displayRole.toUpperCase(), 
              style: TextStyle(color: user.isAdmin ? Colors.red : colorDeepSage.withOpacity(0.6), 
              fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider()),
            
            _detailRow(Icons.email_outlined, "Email", user.email),
            const SizedBox(height: 15),
            _detailRow(Icons.storefront_outlined, "Nama Toko", user.storeName),
            const SizedBox(height: 15),
            _detailRow(Icons.vpn_key_outlined, "ID Akun", "#${user.id}"),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorDeepSage,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                ),
                child: const Text("Tutup Detail", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: colorDeepSage, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: colorDeepSage)),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------
// FORM DIALOG (TAMBAH/EDIT)
// ---------------------------------------------------------
class _UserFormDialog extends ConsumerStatefulWidget {
  final User? user;
  const _UserFormDialog({this.user});

  @override
  ConsumerState<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<_UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _storeNameController;
  String _selectedRole = 'toko';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.username ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _storeNameController = TextEditingController(text: widget.user?.storeName ?? '');
    _selectedRole = widget.user?.role ?? 'toko';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final token = ref.read(authProvider).token!;
      final authService = AuthService();

      if (widget.user == null) {
        await authService.createUser(
          token: token, username: _usernameController.text, email: _emailController.text,
          password: _passwordController.text, storeName: _storeNameController.text, role: _selectedRole,
        );
      } else {
        await authService.updateUser(
          token: token, userId: widget.user!.id, username: _usernameController.text,
          email: _emailController.text, storeName: _storeNameController.text,
          password: _passwordController.text.isEmpty ? null : _passwordController.text,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ref.invalidate(usersProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(color: colorMilkWhite, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
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
              Text(widget.user == null ? 'Daftarkan Akun Baru' : 'Perbarui Profil User', 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: colorDeepSage)),
              const SizedBox(height: 25),
              
              _inputField("Username", _usernameController, Icons.person_outline_rounded),
              const SizedBox(height: 15),
              _inputField("Email", _emailController, Icons.alternate_email_rounded, isEmail: true),
              const SizedBox(height: 15),
              _inputField(widget.user == null ? "Password" : "Password Baru (Opsional)", _passwordController, Icons.lock_open_rounded, isPass: true),
              const SizedBox(height: 15),
              _inputField("Nama Toko / Unit", _storeNameController, Icons.storefront_rounded),
              const SizedBox(height: 15),
              
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: _inputDecoration("Hak Akses (Role)", Icons.verified_user_outlined),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                  DropdownMenuItem(value: 'toko', child: Text('Pemilik Toko')),
                ],
                onChanged: widget.user == null ? (v) => setState(() => _selectedRole = v!) : null,
              ),
              
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorDeepSage, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(widget.user == null ? 'Simpan Akun' : 'Simpan Perubahan', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, IconData icon, {bool isPass = false, bool isEmail = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: _inputDecoration(label, icon),
      validator: (v) {
        if (widget.user == null && (v?.isEmpty ?? true)) return 'Wajib diisi';
        if (isEmail && v != null && v.isNotEmpty && !v.contains('@')) return 'Email tidak valid';
        return null;
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colorDeepSage),
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
    );
  }
}