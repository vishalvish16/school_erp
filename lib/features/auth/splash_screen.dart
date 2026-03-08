import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gif_view/gif_view.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/design_system.dart';
import '../../core/services/local_storage_service.dart';
import '../../utils/portal_resolver.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _redirected = false;

  Future<void> _decideNavigation() async {
    if (_redirected || !mounted) return;
    final storage = LocalStorageService();

    // 1. Valid session → straight to dashboard
    if (await storage.hasValidSession()) {
      if (!mounted) return;
      _redirected = true;
      final portalType = await storage.getPortalType();
      final route = PortalResolver.getDashboardRoute(portalType ?? '');
      if (mounted) context.go(route.isEmpty ? '/dashboard' : route);
      return;
    }

    // 2. Web: no session → platform login (subdomain flow)
    if (kIsWeb) {
      if (!mounted) return;
      _redirected = true;
      if (mounted) context.go('/login');
      return;
    }

    // 3. Mobile: school saved → go to appropriate login
    final school = await storage.getSavedSchool();
    if (school != null) {
      if (!mounted) return;
      _redirected = true;
      final portalType = await storage.getPortalType();
      final route = PortalResolver.getLoginRoute(portalType ?? 'unknown');
      if (mounted) context.go(route);
      return;
    }

    // 4. Mobile: nothing saved → school setup first time
    if (!mounted) return;
    _redirected = true;
    if (mounted) context.go('/school-setup');
  }

  void _navigateFallback() {
    if (!_redirected && mounted) {
      _redirected = true;
      context.go(kIsWeb ? '/login' : '/school-setup');
    }
  }

  @override
  void initState() {
    super.initState();
    _decideNavigation();
    // Fallback: redirect after 5s if decision never completes
    Future.delayed(const Duration(seconds: 5), _navigateFallback);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                color: Colors.white,
              ),
              child: GifView.asset(
                'assets/animations/logo_gif.gif',
                fit: BoxFit.contain,
                loop: false,
                onFinish: _decideNavigation,
                errorBuilder: (context, error, stackTrace) {
                  return const AppLoader(size: 60);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
