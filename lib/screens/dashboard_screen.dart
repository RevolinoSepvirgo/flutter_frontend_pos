import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:point_of_sales_flutter/screens/order_history.dart';
import '../providers/auth_provider.dart';
import 'pos_screen.dart';
import 'products_screen.dart';
import 'categories_screen.dart';
import 'users_screen.dart';
import 'report_screen.dart';

// Palette Warna Premium
const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);
const Color colorGold = Color(0xFFC5A358); // Warna tambahan untuk aksen kasir

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 2; // Default ke Kasir (tengah)

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorMilkWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Sign Out', 
          style: TextStyle(color: colorDeepSage, fontWeight: FontWeight.w900)),
        content: const Text('Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorDeepSage,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.isAdmin ?? false;

    late final List<Widget> screens;
    late final List<IconData> icons;
    late final List<String> labels;

    if (isAdmin) {
      screens = const [UsersScreen()];
      icons = [Icons.supervised_user_circle_rounded];
      labels = ['Users'];
    } else {
      // URUTAN BARU: Report, Transaksi, Kasir (Tengah), Kategori, Produk
      screens = const [
        ReportScreen(),
        OrderHistoryScreen(),
        POSScreen(),
        CategoriesScreen(),
        ProductsScreen(),
      ];
      icons = [
        Icons.analytics_rounded,
        Icons.receipt_long_rounded,
        Icons.local_mall_rounded, // Kasir
        Icons.grid_view_rounded,
        Icons.inventory_2_rounded,
      ];
      labels = ['Report', 'Transaksi', 'Kasir', 'Kategori', 'Produk'];
    }

    // Proteksi index jika berganti role
    int safeIndex = _selectedIndex >= screens.length ? 0 : _selectedIndex;

    return Scaffold(
      backgroundColor: colorDeepSage,
      body: Column(
        children: [
          // 1. HEADER
          SafeArea(
            bottom: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAdmin ? 'ADMIN' : (user?.storeName?.toUpperCase() ?? 'STORE'),
                        style: const TextStyle(
                          color: colorMilkWhite,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        isAdmin ? "User Management" : "Workspace Active",
                        style: TextStyle(
                          color: colorMilkWhite.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorMilkWhite.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.logout_rounded, color: colorMilkWhite, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. MAIN CONTENT
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: colorMilkWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(50),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(50)),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: screens[safeIndex],
                ),
              ),
            ),
          ),

          // 3. MENU DOCKED (URUTAN & UKURAN CUSTOM)
          if (!isAdmin)
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 10,
                top: 10,
              ),
              decoration: const BoxDecoration(
                color: colorDeepSage,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(icons.length, (index) {
                  bool isSelected = safeIndex == index;
                  bool isCenter = index == 2; // Index 2 adalah Kasir

                  return InkWell(
                    onTap: () => _onItemTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: isCenter ? 20 : 12, 
                        vertical: isCenter ? 12 : 8
                      ),
                      decoration: BoxDecoration(
                        // Jika kasir, buat background Putih atau Sage Terang saat dipilih
                        color: isCenter 
                            ? (isSelected ? colorMilkWhite : colorMilkWhite.withOpacity(0.1))
                            : (isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isCenter && isSelected 
                            ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)] 
                            : [],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icons[index],
                            color: isCenter && isSelected 
                                ? colorDeepSage // Ikon gelap jika background putih (Kasir terpilih)
                                : (isSelected ? colorMilkWhite : colorMilkWhite.withOpacity(0.4)),
                            size: isCenter ? 32 : 24, // Kasir lebih besar
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[index],
                            style: TextStyle(
                              color: isCenter && isSelected 
                                  ? colorDeepSage 
                                  : (isSelected ? colorMilkWhite : colorMilkWhite.withOpacity(0.4)),
                              fontSize: isCenter ? 12 : 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}