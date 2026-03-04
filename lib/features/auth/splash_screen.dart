import 'package:flutter/material.dart';
import 'package:gif_view/gif_view.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/design_system.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _redirected = false;

  void _navigateToLogin() {
    if (!_redirected && mounted) {
      _redirected = true;
      context.go('/login');
    }
  }

  @override
  void initState() {
    super.initState();
    // Fallback: redirect after 5s if GIF never fires onFinish (e.g. load error)
    Future.delayed(const Duration(seconds: 5), _navigateToLogin);
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
                onFinish: _navigateToLogin,
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
