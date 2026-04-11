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
      builder: (_, _) => Container(
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

/// Shimmer placeholder that mirrors a data table layout.
///
/// Renders a [Card] with a header row + [rowCount] data rows, each column
/// sized proportionally to [columnWidths]. Wrap with
/// `Center > ConstrainedBox(maxWidth: totalWidth)` to match the real table.
class ShimmerTableLoadingWidget extends StatelessWidget {
  const ShimmerTableLoadingWidget({
    super.key,
    required this.columnWidths,
    this.rowCount = 8,
    this.maxWidth,
  });

  /// Logical pixel widths for each column (same list used in ListTableView).
  final List<double> columnWidths;

  /// Number of shimmer data rows to render.
  final int rowCount;

  /// Optional max-width constraint — should match the real table's maxWidth.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final headerBg = isDark
        ? const Color(0xFF0A1628)
        : const Color(0xFFDBEAFE);

    Widget table = Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── shimmer header ─────────────────────────────────────────────
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: columnWidths.map((w) {
                  final isLast = w == columnWidths.last;
                  return Padding(
                    padding: EdgeInsets.only(right: isLast ? 0 : 8),
                    child: SizedBox(
                      width: w - (isLast ? 0 : 8),
                      child: Center(
                        child: ShimmerLoadingWidget(
                          width: w * 0.55,
                          height: 10,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // ── shimmer rows ───────────────────────────────────────────────
          ...List.generate(rowCount, (i) => _ShimmerTableRow(
            columnWidths: columnWidths,
            isEven: i.isEven,
            isDark: isDark,
            scheme: scheme,
          )),
        ],
      ),
    );

    if (maxWidth != null) {
      table = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth!),
          child: table,
        ),
      );
    }

    return table;
  }
}

class _ShimmerTableRow extends StatelessWidget {
  const _ShimmerTableRow({
    required this.columnWidths,
    required this.isEven,
    required this.isDark,
    required this.scheme,
  });

  final List<double> columnWidths;
  final bool isEven;
  final bool isDark;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: isEven
            ? Colors.transparent
            : (isDark
                ? Colors.white.withValues(alpha: 0.025)
                : Colors.black.withValues(alpha: 0.018)),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: columnWidths.map((w) {
            final isLast = w == columnWidths.last;
            // Last column (actions) — render a small circle shimmer
            if (isLast) {
              return SizedBox(
                width: w,
                child: Center(
                  child: ShimmerLoadingWidget(
                    width: 24,
                    height: 24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: w - 8,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoadingWidget(
                      width: (w - 8) * 0.72,
                      height: 12,
                    ),
                    if (w >= 160) ...[
                      const SizedBox(height: 5),
                      ShimmerLoadingWidget(
                        width: (w - 8) * 0.45,
                        height: 9,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
