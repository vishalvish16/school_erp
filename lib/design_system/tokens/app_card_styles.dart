// =============================================================================
// FILE: lib/core/theme/app_card_styles.dart
// PURPOSE: Reusable card widget variants for the School ERP Admin UI
// =============================================================================

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

// ── CardTheme (used in ThemeData) ────────────────────────────────────────────

CardThemeData buildCardTheme(ColorScheme scheme) {
  return CardThemeData(
    elevation: AppElevation.sm,
    color: scheme.surface,
    shadowColor: scheme.shadow.withAlpha(30),
    surfaceTintColor: Colors.transparent,
    shape: AppRadius.cardShape,
    clipBehavior: Clip.antiAlias,
    margin: EdgeInsets.zero,
  );
}

// ── AppCard — base reusable card widget ──────────────────────────────────────

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.color,
    this.border,
    this.borderRadius,
    this.elevation = AppElevation.sm,
    this.onTap,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Color? color;
  final BoxBorder? border;
  final BorderRadius? borderRadius;
  final double elevation;
  final VoidCallback? onTap;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effectiveRadius = borderRadius ?? AppRadius.brLg;
    final effectiveColor = color ?? scheme.surface;

    final container = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: effectiveRadius,
        border: border ?? Border.all(
          color: scheme.outline.withAlpha(100),
          width: 1,
        ),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: scheme.shadow.withAlpha(
                    (elevation * 5).clamp(0, 60).round(),
                  ),
                  blurRadius: elevation * 2.5,
                  offset: Offset(0, elevation * 0.5),
                ),
              ]
            : null,
      ),
      clipBehavior: clipBehavior,
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: effectiveRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: effectiveRadius,
          splashColor: scheme.primary.withAlpha(20),
          highlightColor: scheme.primary.withAlpha(10),
          child: container,
        ),
      );
    }

    return container;
  }
}

// ── AppStatCard — metric / KPI card ──────────────────────────────────────────

class AppStatCard extends StatelessWidget {
  const AppStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.trend,
    this.trendUp,
    this.iconColor,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final String? trend;
  final bool? trendUp;
  final Color? iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = iconColor ?? scheme.primary;

    return AppCard(
      padding: AppSpacing.cardPadding,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.caption(color: scheme.onSurfaceVariant)),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withAlpha(26),
                  borderRadius: AppRadius.brMd,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          AppSpacing.vGapSm,
          Text(value, style: AppTextStyles.metric(color: scheme.onSurface)),
          if (subtitle != null || trend != null) ...[
            AppSpacing.vGapXs,
            Row(
              children: [
                if (trend != null) ...[
                  Icon(
                    trendUp == true
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 14,
                    color: trendUp == true
                        ? AppColors.success600
                        : AppColors.error600,
                  ),
                  AppSpacing.hGapXs,
                  Text(
                    trend!,
                    style: AppTextStyles.caption(
                      color: trendUp == true
                          ? AppColors.success600
                          : AppColors.error600,
                    ),
                  ),
                  AppSpacing.hGapSm,
                ],
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyles.caption(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── AppSectionCard — page section container ───────────────────────────────────

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding,
    this.color,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lTitle = title;
    final lSubtitle = subtitle;
    final lTrailing = trailing;
    final hasHeader = lTitle != null || lTrailing != null;

    return AppCard(
      elevation: AppElevation.xs,
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasHeader) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (lTitle != null)
                          Text(lTitle, style: AppTextStyles.h5(color: scheme.onSurface)),
                        if (lSubtitle != null) ...[
                          AppSpacing.vGapXs,
                          Text(lSubtitle, style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant)),
                        ],
                      ],
                    ),
                  ),
                  if (lTrailing != null) ...[lTrailing],
                ],
              ),
            ),
            Divider(height: 1, color: scheme.outline.withAlpha(80)),
          ],
          Padding(
            padding: padding ?? AppSpacing.cardPadding,
            child: child,
          ),
        ],
      ),
    );
  }
}
