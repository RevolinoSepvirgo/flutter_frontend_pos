import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'providers/auth_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  // Kita buat status inisialisasi aplikasi
  bool _isAppLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Berikan durasi minimal Splash Screen (misal 2.5 detik agar animasi selesai)
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (mounted) {
      setState(() {
        _isAppLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'POS Kasir',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
        // ... (tema lainnya tetap sama)
      ),
      // Gunakan AnimatedSwitcher agar transisi antar screen tidak kaku/kaget
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _buildHome(authState),
      ),
    );
  }

  Widget _buildHome(AuthState authState) {
    // LOGIKA PERBAIKAN:
    // Kita tetap di Splash selama:
    // - Timer _isAppLoading belum selesai (Timer manual)
    // - ATAU authState sedang loading (Cek token ke storage/API)
    if (_isAppLoading || authState.isLoading) {
      return const SplashScreen(key: ValueKey('splash'));
    }

    // Jika sudah selesai loading, baru tentukan Dashboard atau Login
    if (authState.isAuthenticated) {
      return const DashboardScreen(key: ValueKey('dashboard'));
    }

    return const LoginScreen(key: ValueKey('login'));
  }
}