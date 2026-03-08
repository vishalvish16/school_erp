// =============================================================================
// FILE: lib/widgets/super_admin/stat_card_widget.dart
// PURPOSE: Stat card for Super Admin dashboard
// =============================================================================

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class SuperAdminStatCard extends StatelessWidget {
  const SuperAdminStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.change,
    this.changeType,
    this.accentColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final String? change;
  final String? changeType; // 'up' | 'down' | 'neutral'
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accentColor ?? scheme.primary;
    final isCompact = !kIsWeb && MediaQuery.of(context).size.width < 768;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: isCompact ? 20 : 24, color: color),
                ),
                if (change != null) ...[
                  const Spacer(),
                  Text(
                    change!,
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 12,
                      color: changeType == 'up'
                          ? Colors.green
                          : changeType == 'down'
                              ? Colors.red
                              : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: isCompact ? 8 : 12),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
