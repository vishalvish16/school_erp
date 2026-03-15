// =============================================================================
// FILE: lib/features/auth/auth_screen_layout.dart
// PURPOSE: Shared layout for all auth screens — header, left panel, footer
// Same structure as login_screen.dart
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../design_system/design_system.dart';

/// Wraps auth content with header, left branding panel (web), footer (web), background
class AuthScreenLayout extends StatelessWidget {
  const AuthScreenLayout({
    super.key,
    required this.child,
    this.loading = false,
  });

  final Widget child;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < AuthSizes.breakpointLogin;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AuthAssets.background, fit: BoxFit.cover),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < AuthSizes.breakpointLogin;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMobile
                        ? [
                            AuthColors.overlayLight(0.28),
                            AuthColors.overlayLight(0.15),
                          ]
                        : [
                            AuthColors.overlayLight(0.15),
                            AuthColors.overlayLight(0.05),
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(isMobile: isMobile),
                Expanded(
                  child: Center(
                    child: ScrollConfiguration(
                      behavior: ScrollBehavior().copyWith(scrollbars: false),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AuthSizes.scrollPadding,
                          vertical: AuthSizes.scrollPadding,
                        ),
                        child: isMobile
                            ? _buildMobileLayout(child)
                            : _buildWebLayout(child),
                      ),
                    ),
                  ),
                ),
                if (!isMobile) _buildFooter(isMobile: false),
              ],
            ),
          ),
          if (loading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AuthSizes.glassBlur,
                  sigmaY: AuthSizes.glassBlur,
                ),
                child: Container(
                  color: AuthColors.overlayDark(0.2),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: AuthSizes.loadingStrokeWidth,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWebLayout(Widget content) {
    return Container(
      constraints: const BoxConstraints(maxWidth: AuthSizes.maxContentWidth),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 6, child: _buildBrandingPanel(isMobile: false)),
          const SizedBox(width: AuthSizes.brandingGap),
          Expanded(flex: 4, child: content),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(Widget content) {
    return Column(
      children: [
        content,
        SizedBox(height: AuthSizes.sectionGap),
        _buildMobileStatistics(),
      ],
    );
  }

  Widget _buildHeader({required bool isMobile}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AuthSizes.headerPaddingV,
        horizontal: AuthSizes.headerPaddingH,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                AuthAssets.logo,
                height: isMobile ? AuthSizes.logoHeightMobile : AuthSizes.logoHeightWeb,
                fit: BoxFit.contain,
                isAntiAlias: true,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.school_rounded,
                  size: isMobile ? AuthSizes.logoHeightMobile : AuthSizes.logoHeightWeb,
                  color: AuthColors.primary,
                ),
              ),
              if (isMobile) ...[
                SizedBox(height: AuthSizes.taglineGap),
                _buildMobileTagline(),
              ],
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: const ThemeToggleButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTagline() {
    final dotSeparator = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AuthSizes.taglineDotPadding),
      child: Container(
        width: AuthSizes.taglineDotSize,
        height: AuthSizes.taglineDotSize,
        decoration: const BoxDecoration(
          color: AuthColors.textMuted,
          shape: BoxShape.circle,
        ),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AuthAssets.protect,
          width: AuthSizes.taglineIconSize,
          height: AuthSizes.taglineIconSize,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
            Icons.shield,
            size: AuthSizes.taglineIconSize,
            color: AuthColors.primary,
          ),
        ),
        const SizedBox(width: AuthSizes.taglineIconGap),
        Text(AuthStrings.protect, style: AuthTextStyles.tagline),
        dotSeparator,
        Text(AuthStrings.track, style: AuthTextStyles.tagline),
        dotSeparator,
        Text(AuthStrings.automate, style: AuthTextStyles.tagline),
      ],
    );
  }

  Widget _buildBrandingPanel({required bool isMobile}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AuthSizes.glassBlur,
          sigmaY: AuthSizes.glassBlur,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AuthColors.overlayLight(0.25),
            borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
            border: Border.all(
              color: AuthColors.overlayLight(0.5),
              width: AuthSizes.glassBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: AuthColors.overlayDark(0.08),
                blurRadius: AuthSizes.glassShadowBlur,
                offset: Offset(0, AuthSizes.glassShadowOffset),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(
              isMobile ? AuthSizes.brandingPaddingMobile : AuthSizes.brandingPaddingWeb,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                _buildFeaturePoint(AuthStrings.featureAiShield),
                _buildFeaturePoint(AuthStrings.featureMultiCampus),
                _buildFeaturePoint(AuthStrings.featureAnalytics),
                _buildFeaturePoint(AuthStrings.featureCompliance),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AuthSizes.featurePointGap),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AuthSizes.featurePointIconPadding),
            decoration: const BoxDecoration(
              color: AuthColors.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: AuthSizes.featurePointIconSize,
              color: Colors.white,
            ),
          ),
          SizedBox(width: AuthSizes.featurePointTextGap),
          Text(text, style: AuthTextStyles.featurePoint),
        ],
      ),
    );
  }

  Widget _buildMobileStatistics() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatBubble(AuthStrings.statStudents, AuthStrings.statStudentsLabel),
          SizedBox(width: AuthSizes.statBubbleGap),
          _buildStatBubble(AuthStrings.statAttendance, AuthStrings.statAttendanceLabel),
          SizedBox(width: AuthSizes.statBubbleGap),
          _buildStatBubble(AuthStrings.statIncidents, AuthStrings.statIncidentsLabel),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String val, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AuthSizes.statBubblePaddingH,
        vertical: AuthSizes.statBubblePaddingV,
      ),
      decoration: BoxDecoration(
        color: AuthColors.overlayLight(0.25),
        borderRadius: BorderRadius.circular(AuthSizes.statBubbleRadius),
        border: Border.all(color: AuthColors.overlayLight(0.4)),
      ),
      child: Column(
        children: [
          Text(val, style: AuthTextStyles.statValue),
          Text(label, style: AuthTextStyles.statLabel),
        ],
      ),
    );
  }

  Widget _buildFooter({required bool isMobile}) {
    final gap = isMobile ? AuthSizes.footerGapMobile : AuthSizes.footerGapWeb;
    final dotSeparator = Padding(
      padding: EdgeInsets.symmetric(horizontal: gap / 2),
      child: Container(
        width: AuthSizes.taglineDotSize,
        height: AuthSizes.taglineDotSize,
        decoration: const BoxDecoration(
          color: AuthColors.textMuted,
          shape: BoxShape.circle,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AuthSizes.footerPaddingV,
        horizontal: AuthSizes.footerPaddingH,
      ),
      child: isMobile
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFooterIcon(AuthAssets.protect, isMobile),
                      SizedBox(width: AuthSizes.footerGapMobile),
                      _buildFooterIcon(AuthAssets.track, isMobile),
                      SizedBox(width: AuthSizes.footerGapMobile),
                      _buildFooterIcon(AuthAssets.automate, isMobile),
                    ],
                  ),
                  SizedBox(height: AuthSizes.footerTextGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AuthStrings.protect, style: AuthTextStyles.tagline),
                      dotSeparator,
                      Text(AuthStrings.track, style: AuthTextStyles.tagline),
                      dotSeparator,
                      Text(AuthStrings.automate, style: AuthTextStyles.tagline),
                    ],
                  ),
                ],
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFooterIcon(AuthAssets.protect, isMobile),
                    SizedBox(width: AuthSizes.footerGapWeb),
                    _buildFooterIcon(AuthAssets.track, isMobile),
                    SizedBox(width: AuthSizes.footerGapWeb),
                    _buildFooterIcon(AuthAssets.automate, isMobile),
                  ],
                ),
                SizedBox(height: AuthSizes.footerTextGap),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AuthStrings.protect, style: AuthTextStyles.tagline),
                    dotSeparator,
                    Text(AuthStrings.track, style: AuthTextStyles.tagline),
                    dotSeparator,
                    Text(AuthStrings.automate, style: AuthTextStyles.tagline),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildFooterIcon(String assetPath, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(AuthSizes.footerIconPadding),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AuthColors.overlayLight(0.08),
            blurRadius: AuthSizes.formFieldShadowBlur,
            offset: const Offset(0, AuthSizes.formFieldShadowOffset),
          ),
        ],
      ),
      child: Image.asset(
        assetPath,
        width: isMobile ? AuthSizes.footerIconMobile : AuthSizes.footerIconWeb,
        height: isMobile ? AuthSizes.footerIconMobile : AuthSizes.footerIconWeb,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => Icon(
          Icons.verified_user,
          size: isMobile ? AuthSizes.footerIconMobile : AuthSizes.footerIconWeb,
          color: AuthColors.primary,
        ),
      ),
    );
  }
}
