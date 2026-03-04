import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/design_system.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for the animation to play or data to load
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      // GoRouter's redirect logic in app_router.dart will take over
      // and send user to /login or /dashboard automatically.
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: Colors.black),
        child: Stack(
          children: [
            // ── Background Layer: Vertical Fade ──────────────────────────────
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.7],
                    colors: [
                      Color(0xFF1E40AF), // Deep Blue Top
                      Colors.black, // Fade into Black
                    ],
                  ),
                ),
              ),
            ),

            // ── Top-Left to Right: Blue to Light Blue Glow ───────────────────
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.5,
                    colors: [
                      const Color(
                        0xFF3B82F6,
                      ).withValues(alpha: 0.4), // Light Blue
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── The "Spread" Effect: Central Radial Glow ─────────────────────
            // This spreads from the icon out to all 4 sides
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      const Color(
                        0xFF3B82F6,
                      ).withValues(alpha: 0.8), // Vibrant center
                      const Color(0xFF1D4ED8).withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.8, 1.0],
                  ),
                ),
              ),
            ),

            // ── Bottom Shadow mask to ensure black bottom ────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: MediaQuery.of(context).size.height * 0.4,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87, Colors.black],
                  ),
                ),
              ),
            ),

            // ── GIF Content ──────────────────────────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                          blurRadius: 80,
                          spreadRadius: 40,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/animations/logo_gif.gif',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const AppLoader(size: 60);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
