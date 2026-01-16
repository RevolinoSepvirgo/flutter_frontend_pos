import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'pos_screen.dart';
import 'products_screen.dart';
import 'categories_screen.dart';
import 'users_screen.dart';
import 'report_screen.dart';

// Palette Warna Premium sesuai gambar
const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);
const Color colorDeepSageLight = Color(0xFF627A5B);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Sign Out', 
          style: TextStyle(color: colorDeepSage, fontWeight: FontWeight.w900, fontSize: 24)),
        content: const Text('Are you sure you want to leave the workspace?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: colorDeepSage,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
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

    // Logic Screens & Icons
    late final List<Widget> screens;
    late final List<IconData> icons;
    late final List<String> labels;

    if (isAdmin) {
      screens = const [UsersScreen()];
      icons = [Icons.supervised_user_circle_rounded];
      labels = ['Users'];
    } else {
      screens = const [POSScreen(), ProductsScreen(), CategoriesScreen(), ReportScreen()];
      icons = [
        Icons.local_mall_rounded,
        Icons.inventory_2_rounded, // ✅ SUDAH DIPERBAIKI (huruf kecil 'i')
        Icons.grid_view_rounded,
        Icons.bubble_chart_rounded
      ];
      labels = ['Kasir', 'Produk', 'Kategori', 'Report'];
    }

    return Scaffold(
      backgroundColor: colorMilkWhite,
      body: Stack(
        children: [
          // 1. HEADER ASIMETRIS
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.22,
            child: Container(
              decoration: const BoxDecoration(
                color: colorDeepSage,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(60),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(25, 60, 25, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAdmin ? 'ADMIN' : (user?.storeName?.toUpperCase() ?? 'POS'),
                        style: const TextStyle(
                          color: colorMilkWhite,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        isAdmin ? "Control Center" : "Store Management",
                        style: TextStyle(
                          color: colorMilkWhite.withOpacity(0.6),
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _logout,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.logout_rounded, color: colorMilkWhite, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorMilkWhite.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: colorMilkWhite,
                          child: Text(
                            user?.username[0].toUpperCase() ?? 'U',
                            style: const TextStyle(color: colorDeepSage, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),

          // 2. MAIN CONTENT AREA
          Positioned(
            top: MediaQuery.of(context).size.height * 0.18,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: colorMilkWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(40)),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: screens[_selectedIndex],
                ),
              ),
            ),
          ),

          // 3. FLOATING DOCK NAVIGATION
          Positioned(
            bottom: 25,
            left: 20,
            right: 20,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: colorDeepSage,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: colorDeepSage.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(icons.length, (index) {
                  bool isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () => _onItemTapped(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? colorMilkWhite : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icons[index],
                            color: isSelected ? colorDeepSage : colorMilkWhite.withOpacity(0.5),
                            size: 26,
                          ),
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                labels[index],
                                style: const TextStyle(
                                  color: colorDeepSage,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}