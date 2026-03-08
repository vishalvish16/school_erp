// =============================================================================
// FILE: lib/features/auth/group_admin_login_screen.dart
// PURPOSE: Group Admin login — {groupslug}.vidyron.in (e.g. dpsgroup.vidyron.in)
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../models/school_identity.dart';
import '../../utils/subdomain_resolver.dart';
import '../../widgets/group_identity_banner.dart';
import 'auth_screen_layout.dart';

class GroupAdminLoginScreen extends ConsumerStatefulWidget {
  const GroupAdminLoginScreen({super.key});

  @override
  ConsumerState<GroupAdminLoginScreen> createState() => _GroupAdminLoginScreenState();
}

class _GroupAdminLoginScreenState extends ConsumerState<GroupAdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  int _selectedTab = 0; // 0=Password, 1=OTP
  SchoolIdentity? _identity;
  String? _errorMessage;
  bool _isLoading = false;
  bool _subdomainResolved = false; // Used to avoid showing card before resolve

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _resolveSubdomain();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _resolveSubdomain() async {
    final resolver = ref.read(subdomainResolverProvider);
    final sub = await SubdomainResolver.getCurrentSubdomain();
    if (sub == null || sub.isEmpty) {
      if (mounted) setState(() {
        _subdomainResolved = true;
        _errorMessage = 'Invalid URL. Use {group}.vidyron.in';
      });
      return;
    }
    final identity = await resolver.resolve(sub);
    if (mounted) {
      setState(() {
        _subdomainResolved = true;
        if (identity == null) {
          _errorMessage = 'Invalid URL';
        } else if (identity.type == 'school') {
          context.go('/login/school');
          return;
        } else {
          _identity = identity;
        }
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    // TODO: Call POST /auth/group-admin/login
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (!_subdomainResolved) {
      content = const Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_identity != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: GroupIdentityBanner(
                identity: _identity!,
                showSchoolList: true,
                schoolNames: const [],
              ),
            ),
          _buildLoginCard(),
        ],
      );
    }

    return AuthScreenLayout(
      loading: _isLoading,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
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
                  ],
                ),
                const SizedBox(height: 24),
                if (_selectedTab == 0) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: AuthStrings.email,
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
                ] else ...[
                  const Text('OTP login — Enter mobile, send OTP', style: AuthTextStyles.tagline),
                  const SizedBox(height: 16),
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Mobile number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isLoading ? null : () {},
                    child: Text(_isLoading ? 'Sending...' : 'Send OTP'),
                  ),
                ],
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
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
