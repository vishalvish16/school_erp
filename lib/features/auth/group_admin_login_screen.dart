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
import 'group_admin_login_provider.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../design_system/tokens/app_spacing.dart';

class GroupAdminLoginScreen extends ConsumerStatefulWidget {
  const GroupAdminLoginScreen({super.key});

  @override
  ConsumerState<GroupAdminLoginScreen> createState() => _GroupAdminLoginScreenState();
}

class _GroupAdminLoginScreenState extends ConsumerState<GroupAdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _groupSlugController = TextEditingController();
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
    _groupSlugController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _resolveSubdomain() async {
    final resolver = ref.read(subdomainResolverProvider);
    final sub = await SubdomainResolver.getCurrentSubdomain();
    if (sub == null || sub.isEmpty) {
      if (mounted) {
        setState(() {
          _subdomainResolved = true;
          _errorMessage = null; // Allow manual group slug entry for localhost
        });
      }
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

  Future<SchoolIdentity?> _resolveGroupBySlug(String slug) async {
    if (slug.trim().isEmpty) return null;
    final resolver = ref.read(subdomainResolverProvider);
    return resolver.resolve(slug.trim());
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    String? groupId = _identity?.id;
    if (groupId == null || groupId.isEmpty) {
      final slug = _groupSlugController.text.trim();
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      final identity = await _resolveGroupBySlug(slug);
      if (!mounted) return;
      if (identity == null || identity.type != 'group') {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Group not found. Check the slug.';
        });
        return;
      }
      groupId = identity.id;
      setState(() => _identity = identity);
    }

    ref.read(groupAdminLoginProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text,
      groupId,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GroupAdminLoginState>(groupAdminLoginProvider, (previous, next) {
      if (!mounted) return;
      if (next.isLoading) {
        setState(() => _isLoading = true);
      } else {
        setState(() => _isLoading = false);
        if (next.errorMessage != null) {
          setState(() => _errorMessage = next.errorMessage);
        }
      }
      // Navigate to OTP verification when backend requires device OTP
      if (next.requiresOtp &&
          previous?.requiresOtp != true &&
          next.otpSessionId != null &&
          next.otpSessionId!.isNotEmpty) {
        final sessionId = next.otpSessionId!;
        final masked = next.maskedPhone ?? '';
        final maskedEmail = next.maskedEmail ?? '';
        final otpSentTo = next.otpSentTo ?? '';
        final devOtp = next.devOtp;
        final q =
            'otp_session_id=$sessionId&masked_phone=${Uri.encodeComponent(masked)}&masked_email=${Uri.encodeComponent(maskedEmail)}&otp_sent_to=${Uri.encodeComponent(otpSentTo)}&portal_type=group_admin${devOtp != null ? '&dev_otp=$devOtp' : ''}';
        context.push('/device-verification?$q');
      }
    });

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
                    Tab(text: AppStrings.passwordTab),
                    Tab(text: AppStrings.otpTab),
                  ],
                ),
                AppSpacing.vGapXl,
                if (_selectedTab == 0) ...[
                  if (_identity == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _groupSlugController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.groupSlugOrId,
                          hintText: AppStrings.groupSlugHint,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? AppStrings.groupSlugRequired
                                : null,
                      ),
                    ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: AuthStrings.email,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.isEmpty ? AppStrings.enterEmailError : null,
                  ),
                  AppSpacing.vGapLg,
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
                  AppSpacing.vGapSm,
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(AuthStrings.forgotPassword, style: AuthTextStyles.forgotPassword),
                    ),
                  ),
                ] else ...[
                  const Text(AppStrings.otpLoginTagline, style: AuthTextStyles.tagline),
                  AppSpacing.vGapLg,
                  const TextField(
                    decoration: InputDecoration(
                      labelText: AppStrings.mobileNumber,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  AppSpacing.vGapLg,
                  FilledButton(
                    onPressed: _isLoading ? null : () {},
                    child: Text(_isLoading ? AppStrings.sending : AppStrings.sendOtp),
                  ),
                ],
                AppSpacing.vGapXl,
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_errorMessage!, style: const TextStyle(color: AppColors.error500)),
                        AppSpacing.vGapSm,
                        Text(
                          _errorMessage!.toLowerCase().contains('locked')
                              ? 'Contact your platform administrator to unlock the account in Super Admin → Groups.'
                              : 'Ensure you are assigned as group admin in Super Admin → Groups.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                FilledButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: AuthColors.primary,
                    padding: AppSpacing.paddingVLg,
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
