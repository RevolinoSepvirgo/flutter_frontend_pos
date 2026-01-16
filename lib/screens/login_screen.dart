import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

// Palette Warna Premium (Konsisten)
const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);
const Color colorDeepSageLight = Color(0xFF627A5B);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      body: Stack(
        children: [
          // 1. Decorative Background (Aksen Lingkaran Organik)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: colorDeepSage.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 2. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // LOGO SECTION
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: colorDeepSage.withOpacity(0.1),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.auto_awesome_motion_rounded,
                          size: 60,
                          color: colorDeepSage,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // TITLE SECTION
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 32, letterSpacing: 1),
                          children: [
                            TextSpan(
                              text: 'POS',
                              style: TextStyle(fontWeight: FontWeight.w900, color: colorDeepSage),
                            ),
                            TextSpan(
                              text: 'KASIR',
                              style: TextStyle(fontWeight: FontWeight.w200, color: colorDeepSage),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan masuk untuk melanjutkan',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorDeepSage.withOpacity(0.5),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // INPUT EMAIL
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Email wajib diisi';
                          if (!value.contains('@')) return 'Format email salah';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // INPUT PASSWORD
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                            color: colorDeepSage.withOpacity(0.3),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Password wajib diisi';
                          if (value.length < 6) return 'Minimal 6 karakter';
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: authState.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorDeepSage,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: colorDeepSage.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('MASUK KE SISTEM', 
                                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                                    SizedBox(width: 10),
                                    Icon(Icons.arrow_forward_rounded, size: 20),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorDeepSage.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w600, color: colorDeepSage),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: colorDeepSage.withOpacity(0.4), fontSize: 14),
          prefixIcon: Icon(icon, color: colorDeepSage.withOpacity(0.6), size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          errorStyle: const TextStyle(height: 0), // Menyembunyikan teks error bawaan agar tetap clean
        ),
        validator: validator,
      ),
    );
  }
}