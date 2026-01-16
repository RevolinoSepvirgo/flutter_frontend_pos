import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Palette Warna Premium (Konsisten)
const Color colorMilkWhite = Color(0xFFFDFBF0);
const Color colorDeepSage = Color(0xFF465940);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // 1. Animasi Transparansi (Fade In)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    // 2. Animasi Ukuran Logo (Scale) - Efek Pop-up
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // 3. Animasi Geser Teks (Slide Up)
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.decelerate),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorMilkWhite, // Mengubah ke Milk White agar konsisten
      body: Stack(
        children: [
          // Background Glow (Efek Cahaya Sage halus)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    colorDeepSage.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO SECTION
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorDeepSage, // Background Logo Deep Sage
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: colorDeepSage.withOpacity(0.2),
                            blurRadius: 40,
                            offset: const Offset(0, 15),
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_motion_rounded, // Icon yang konsisten dengan Dashboard/Login
                        size: 72,
                        color: colorMilkWhite, // Icon warna Milk White
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),

                // TEXT SECTION (Branding)
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        RichText(
                          text: const TextSpan(
                            style: TextStyle(fontSize: 32, letterSpacing: 4),
                            children: [
                              TextSpan(
                                text: 'POS',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: colorDeepSage,
                                ),
                              ),
                              TextSpan(
                                text: 'KASIR',
                                style: TextStyle(
                                  fontWeight: FontWeight.w200, // Tipis untuk kesan modern boutique
                                  color: colorDeepSage,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'SMART COMMERCE SOLUTION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: colorDeepSage.withOpacity(0.4),
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 80),
                
                // LOADING INDICATOR
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(colorDeepSage), // Spinner warna Sage
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}