// =============================================================================
// FILE: lib/shared/widgets/metric_stat_card.dart
// PURPOSE: KPI / metric tiles — white card, tinted icon box, value, label (Billing reference)
// =============================================================================

import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Dashboard / billing style metric: **icon (in rounded tinted box) → value → label**.
/// Use [compact] for horizontal scroll strips on narrow layouts (~148px wide).
class MetricStatCard extends StatelessWidget {
  const MetricStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.compact = false,
    this.onTap,
    this.subtitle,
    this.subtitleColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool compact;
  final VoidCallback? onTap;
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inner = Padding(
      padding: EdgeInsets.all(compact ? 12 : AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(icon, size: compact ? 20 : 24, color: color),
          ),
          SizedBox(height: compact ? 8 : AppSpacing.md),
          Text(
            value,
            style: (compact
                    ? Theme.of(context).textTheme.titleMedium
                    : Theme.of(context).textTheme.titleLarge)
                ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: compact ? 2 : AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: compact ? 11 : null,
                ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: compact ? 2 : 4),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: compact ? 10 : 11,
                    color: subtitleColor ?? AppColors.success500,
                  ),
            ),
          ],
        ],
      ),
    );

    final card = Card(
      elevation: compact ? 0 : null,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.brLg,
        side: BorderSide(
          color: scheme.outlineVariant.withValues(
            alpha: compact ? 0.5 : 0.35,
          ),
        ),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: AppRadius.brLg,
              child: inner,
            )
          : inner,
    );

    return card;
  }
}
