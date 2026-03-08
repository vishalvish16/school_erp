// =============================================================================
// FILE: lib/features/auth/staff_login_screen.dart
// PURPOSE: Staff/Teacher login — same URL as school admin, role auto-detected
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/constants/app_strings.dart';
import '../../models/school_identity.dart';
import '../../utils/subdomain_resolver.dart';
import '../../widgets/school_identity_banner.dart';
import 'auth_screen_layout.dart';

class StaffLoginScreen extends ConsumerStatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  ConsumerState<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends ConsumerState<StaffLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  int _selectedTab = 0; // 0=Password, 1=OTP, 2=QR
  SchoolIdentity? _identity;
  bool _isLoading = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedSchool();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSchool() async {
    if (kIsWeb) {
      final resolver = ref.read(subdomainResolverProvider);
      final sub = await SubdomainResolver.getCurrentSubdomain();
      if (sub == null || sub.isEmpty) return;
      final identity = await resolver.resolve(sub);
      if (mounted && identity != null) setState(() => _identity = identity);
    } else {
      final storage = LocalStorageService();
      final savedSchool = await storage.getSavedSchool();
      if (savedSchool == null && mounted) {
        context.go('/school-setup');
        return;
      }
      if (mounted && savedSchool != null) setState(() => _identity = savedSchool);
    }
  }

  Future<void> _onChangeSchool() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change School?'),
        content: const Text(
          'This will remove your saved school. '
          'You will need to search for your school again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Change'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final storage = LocalStorageService();
    await storage.clearSchool();
    await storage.clearSession();
    if (mounted) context.go('/school-setup');
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // TODO: Call staff login API
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_identity != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: SchoolIdentityBanner(
              identity: _identity!,
              showStats: true,
              showChangeLink: true,
              onChangeTap: _onChangeSchool,
            ),
          ),
        _buildLoginCard(),
      ],
    );

    return AuthScreenLayout(
      loading: _isLoading,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: content,
      ),
    );
  }

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: AuthSizes.glassBlur, sigmaY: AuthSizes.glassBlur),
        child: Container(
          padding: const EdgeInsets.all(AuthSizes.cardPadding),
          decoration: BoxDecoration(
            color: AuthColors.overlayLight(0.25),
            borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
            border: Border.all(color: AuthColors.overlayLight(0.5)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TabBar(
                  controller: _tabController,
                  onTap: (i) => setState(() => _selectedTab = i),
                  labelColor: AuthColors.primary,
                  tabs: const [
                    Tab(text: 'Password'),
                    Tab(text: 'OTP'),
                    Tab(text: 'QR Scan'),
                  ],
                ),
                const SizedBox(height: 24),
                if (_selectedTab == 0) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email / Mobile',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? AppStrings.enterEmailError : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: AuthStrings.password,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? AppStrings.enterPasswordError : null,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(AuthStrings.forgotPassword, style: AuthTextStyles.forgotPassword),
                    ),
                  ),
                  Text(
                    'Your role is auto-detected from your credentials',
                    style: AuthTextStyles.tagline.copyWith(fontSize: 12),
                  ),
                ] else if (_selectedTab == 1) ...[
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Mobile number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Role auto-detected from this number',
                    style: AuthTextStyles.tagline.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: () {}, child: const Text('Send OTP')),
                ] else ...[
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AuthColors.overlayLight(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, size: 64, color: AuthColors.primary),
                          const SizedBox(height: 12),
                          Text(
                            'Scan the QR on your Vidyron ID card',
                            style: AuthTextStyles.tagline,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Drivers: QR auto-assigns your vehicle',
                            style: AuthTextStyles.tagline.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AuthColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(AuthStrings.login, style: AuthTextStyles.buttonPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
