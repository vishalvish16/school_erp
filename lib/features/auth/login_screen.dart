import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_strings.dart';
import 'login_provider.dart';
import 'login_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_login_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      if (mounted) {
        _emailController.text = savedEmail;
        ref.read(loginProvider.notifier).updateEmail(savedEmail);
        ref.read(loginProvider.notifier).toggleRememberMe(true);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(loginProvider.notifier).updateEmail(_emailController.text.trim());
    ref.read(loginProvider.notifier).updatePassword(_passwordController.text);
    await ref.read(loginProvider.notifier).login();
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginProvider);

    ref.listen<LoginState>(loginProvider, (previous, next) {
      if (next.isSuccess && previous?.isSuccess != true) {
        context.go('/dashboard');
      } else if (next.isFailure && previous?.isFailure != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? AppStrings.loginFailed),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    final isMobile = MediaQuery.of(context).size.width < 1000;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Layer
          Image.asset('assets/images/auth_background.jpg', fit: BoxFit.cover),

          // Dark Gradient Overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.1),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // Main Responsive Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: isMobile
                    ? _buildMobileLayout(loginState)
                    : _buildWebLayout(loginState),
              ),
            ),
          ),

          // Global Loading Indicator
          if (loginState.isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.2),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebLayout(LoginState state) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Side: High-impact Branding
          Expanded(flex: 6, child: _buildBrandingPanel(isMobile: false)),
          const SizedBox(width: 80),
          // Right Side: Login Card
          Expanded(
            flex: 4,
            child: _buildGlassLoginCard(state, isMobile: false),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(LoginState state) {
    return Column(
      children: [
        _buildBrandingPanel(isMobile: true),
        const SizedBox(height: 32),
        _buildGlassLoginCard(state, isMobile: true),
        const SizedBox(height: 32),
        _buildMobileStatistics(),
      ],
    );
  }

  Widget _buildBrandingPanel({required bool isMobile}) {
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        // Logo
        Image.asset(
          'assets/images/logo2.png',
          height: isMobile ? 60 : 80,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 12),
        // Tagline with icon
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isMobile
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              Icons.verified_user,
              color: const Color(0xFF2563EB),
              size: isMobile ? 18 : 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Protect • Track • Automate',
              style: TextStyle(
                fontSize: isMobile ? 14 : 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        if (!isMobile) ...[
          const SizedBox(height: 60),
          // Featured Highlights for Desktop (Horizontal)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFeatureHighlight(
                'assets/images/protect.png',
                'Protect',
                false,
              ),
              const SizedBox(width: 48),
              _buildFeatureHighlight('assets/images/track.png', 'Track', false),
              const SizedBox(width: 48),
              _buildFeatureHighlight(
                'assets/images/automate.png',
                'Automate',
                false,
              ),
            ],
          ),
          const SizedBox(height: 48),
          _buildFeaturePoint('Advanced AI Shield Security'),
          _buildFeaturePoint('Unified Multi-Campus Control'),
          _buildFeaturePoint('Real-time Predictive Analytics'),
          _buildFeaturePoint('Automated Compliance Engine'),
        ],
        if (isMobile) ...[
          const SizedBox(height: 32),
          // Featured Highlights for Mobile (Horizontal)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeatureHighlight(
                  'assets/images/protect.png',
                  'Protect',
                  true,
                ),
                const SizedBox(width: 24),
                _buildFeatureHighlight(
                  'assets/images/track.png',
                  'Track',
                  true,
                ),
                const SizedBox(width: 24),
                _buildFeatureHighlight(
                  'assets/images/automate.png',
                  'Automate',
                  true,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeaturePoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFF3B82F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassLoginCard(LoginState state, {required bool isMobile}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Email Input
                _buildStyledField(
                  controller: _emailController,
                  hint: 'Email',
                  icon: Icons.alternate_email_rounded,
                  validator: (v) => v == null || v.isEmpty
                      ? AppStrings.enterEmailError
                      : null,
                ),
                const SizedBox(height: 20),

                // Password Input
                _buildStyledField(
                  controller: _passwordController,
                  hint: 'Password',
                  icon: Icons.security_rounded,
                  isPassword: true,
                  validator: (v) => v == null || v.isEmpty
                      ? AppStrings.enterPasswordError
                      : null,
                ),

                const SizedBox(height: 20),

                // Remember Me & Forgot Password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: Checkbox(
                            value: state.rememberMe,
                            onChanged: (val) => ref
                                .read(loginProvider.notifier)
                                .toggleRememberMe(val ?? false),
                            activeColor: const Color(0xFF2563EB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text(
                        'Forgot Key?',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Access Button
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/signup'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Sign Up ',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Colors.blue[600],
                        ),
                      ],
                    ),
                  ),
                ),

                if (state.isBiometricSupported && state.isBiometricEnabled) ...[
                  const SizedBox(height: 32),
                  const Row(
                    children: [
                      Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(loginProvider.notifier).loginWithBiometrics(),
                    icon: const Icon(Icons.fingerprint_rounded, size: 22),
                    label: const Text(
                      'Biometric Entry',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(
                        color: Color(0xFFE2E8F0),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStyledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                )
              : null,
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildMobileStatistics() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatBubble('1.4k+', 'Active Students'),
          const SizedBox(width: 12),
          _buildStatBubble('98%', 'Attendance'),
          const SizedBox(width: 12),
          _buildStatBubble('Zero', 'Safety Incidents'),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlight(String assetPath, String title, bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon with Highlight/glow background
        Container(
          height: isMobile ? 64 : 88,
          width: isMobile ? 64 : 88,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              assetPath,
              width: isMobile ? 32 : 44,
              height: isMobile ? 32 : 44,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.verified_user, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 14 : 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A), // Deep navy for premium feel
            letterSpacing: 0.5,
            shadows: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
