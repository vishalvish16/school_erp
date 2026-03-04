// =============================================================================
// FILE: lib/shared/widgets/app_card_container.dart
// PURPOSE: Customizable container for cards with responsive width/height
// =============================================================================

import 'package:flutter/material.dart';
import '../tokens/theme.dart';

class AppCardContainer extends StatelessWidget {
  const AppCardContainer({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.elevation = AppElevation.xs,
    this.onTap,
    this.trailing,
    this.color,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: AppSectionCard(
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        padding: padding,
        color: color,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brLg,
          child: child,
        ),
      ),
    );
  }
}
