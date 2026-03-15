// =============================================================================
// FILE: lib/widgets/common/shimmer_loading_widget.dart
// PURPOSE: Reusable shimmer loading placeholder
// =============================================================================

import 'package:flutter/material.dart';
import '../../design_system/tokens/app_spacing.dart';

/// Shimmer loading placeholder for list items, cards, etc.
class ShimmerLoadingWidget extends StatefulWidget {
  const ShimmerLoadingWidget({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<ShimmerLoadingWidget> createState() => _ShimmerLoadingWidgetState();
}

class _ShimmerLoadingWidgetState extends State<ShimmerLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? AppRadius.brXs,
          gradient: LinearGradient(
            begin: Alignment(_animation.value - 1, 0),
            end: Alignment(_animation.value, 0),
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.6),
              color.withValues(alpha: 0.3),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder for a list of list tiles
class ShimmerListLoadingWidget extends StatelessWidget {
  const ShimmerListLoadingWidget({
    super.key,
    this.itemCount = 5,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, i) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Row(
            children: [
              const ShimmerLoadingWidget(width: 40, height: 40),
              AppSpacing.hGapLg,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoadingWidget(
                      width: double.infinity,
                      height: 14,
                    ),
                    AppSpacing.vGapSm,
                    ShimmerLoadingWidget(
                      width: 120,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
