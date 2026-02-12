import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

// Palette Warna (Konsisten dengan POS & Dashboard)
const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller sesuai dengan kebutuhan AuthService
  final _usernameController = TextEditingController();
  final _storeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _storeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).register(
            username: _usernameController.text.trim(),
            storeName: _storeController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registrasi Berhasil! Silakan Login"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke halaman Login
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: colorMilkWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Header
                  const Icon(Icons.store_mall_directory_rounded, size: 80, color: colorDeepSage),
                  const SizedBox(height: 10),
                  const Text(
                    "Daftar Toko Baru",
                    style: TextStyle(
                      fontSize: 28, 
                      fontWeight: FontWeight.w900, 
                      color: colorDeepSage,
                      letterSpacing: 1.2
                    ),
                  ),
                  const Text("Mulai kelola bisnis Anda sekarang"),
                  const SizedBox(height: 40),

                  // Input Username
                  _buildTextField(
                    controller: _usernameController,
                    label: "Username",
                    icon: Icons.person_rounded,
                    validator: (v) => v!.isEmpty ? "Username wajib diisi" : null,
                  ),
                  const SizedBox(height: 15),

                  // Input Nama Toko
                  _buildTextField(
                    controller: _storeController,
                    label: "Nama Toko",
                    icon: Icons.store_rounded,
                    validator: (v) => v!.isEmpty ? "Nama Toko wajib diisi" : null,
                  ),
                  const SizedBox(height: 15),

                  // Input Email
                  _buildTextField(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => !v!.contains('@') ? "Format email salah" : null,
                  ),
                  const SizedBox(height: 15),

                  // Input Password
                  _buildTextField(
                    controller: _passwordController,
                    label: "Password",
                    icon: Icons.lock_rounded,
                    isPassword: true,
                    validator: (v) => v!.length < 6 ? "Password minimal 6 karakter" : null,
                  ),
                  const SizedBox(height: 15),

                  // Input Konfirmasi Password
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: "Konfirmasi Password",
                    icon: Icons.lock_clock_rounded,
                    isPassword: true,
                    validator: (v) => v != _passwordController.text ? "Password tidak cocok" : null,
                  ),
                  const SizedBox(height: 30),

                  // Tombol Register
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorDeepSage,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                      child: authState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "DAFTAR SEKARANG",
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                  // Link kembali ke Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Sudah punya akun? "),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Login Masuk",
                          style: TextStyle(color: colorDeepSage, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: colorDeepSage),
        prefixIcon: Icon(icon, color: colorDeepSage),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: colorDeepSage, width: 2),
        ),
      ),
    );
  }
}