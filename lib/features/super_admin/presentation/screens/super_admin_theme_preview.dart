// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_theme_preview.dart
// PURPOSE: Live preview panel showing how current token colors look on real UI
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/theme/theme_provider.dart';

enum ThemePreviewMode { dashboard, table, form, cards }

class SuperAdminThemePreview extends ConsumerWidget {
  const SuperAdminThemePreview({
    super.key,
    required this.isLight,
    required this.previewMode,
  });

  final bool isLight;
  final ThemePreviewMode previewMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(themeConfigProvider);
    final tokens = isLight ? state.lightTokens : state.darkTokens;

    return Container(
      color: tokens.surfaceBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MiniSidebar(tokens: tokens),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MiniTopbar(tokens: tokens),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: switch (previewMode) {
                      ThemePreviewMode.dashboard => _DashboardPreview(tokens: tokens),
                      ThemePreviewMode.table     => _TablePreview(tokens: tokens),
                      ThemePreviewMode.form      => _FormPreview(tokens: tokens),
                      ThemePreviewMode.cards     => _CardsPreview(tokens: tokens),
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Sidebar ─────────────────────────────────────────────────────────────

class _MiniSidebar extends StatelessWidget {
  const _MiniSidebar({required this.tokens});
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Dashboard', true),
      ('Schools', false),
      ('Plans', false),
      ('Billing', false),
      ('Settings', false),
    ];

    return Container(
      width: 130,
      color: tokens.sidebarBg,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand
          Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: tokens.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Vidyron',
              style: TextStyle(
                color: tokens.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          ...items.map((item) => _NavRow(tokens: tokens, label: item.$1, isActive: item.$2)),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.tokens, required this.label, required this.isActive});
  final AppThemeTokens tokens;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? tokens.navItemActiveBg : tokens.navItemBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(children: [
        Icon(Icons.circle, size: 6,
            color: isActive ? tokens.navItemActiveIcon : tokens.navItemIcon),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? tokens.navItemActiveText : tokens.navItemText,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ]),
    );
  }
}

// ─── Mini Topbar ──────────────────────────────────────────────────────────────

class _MiniTopbar extends StatelessWidget {
  const _MiniTopbar({required this.tokens});
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: tokens.topbarBg,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 28,
              decoration: BoxDecoration(
                color: tokens.inputBg,
                border: Border.all(color: tokens.inputBorder),
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                Icon(Icons.search, size: 13, color: tokens.textHint),
                const SizedBox(width: 6),
                Text('Search...', style: TextStyle(color: tokens.textHint, fontSize: 11)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 13,
            backgroundColor: tokens.primary,
            child: Text('SA', style: TextStyle(color: tokens.onPrimary, fontSize: 9)),
          ),
        ],
      ),
    );
  }
}

// ─── Dashboard Preview ────────────────────────────────────────────────────────

class _DashboardPreview extends StatelessWidget {
  const _DashboardPreview({required this.tokens});
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dashboard',
            style: TextStyle(color: tokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 12),
        _CardsPreview(tokens: tokens),
        const SizedBox(height: 16),
        _TablePreview(tokens: tokens),
      ],
    );
  }
}

// ─── Cards Preview ────────────────────────────────────────────────────────────

class _CardsPreview extends StatelessWidget {
  const _CardsPreview({required this.tokens});
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Total Schools', '124', Icons.school_outlined, 'Active'),
      ('Students', '48,320', Icons.people_outline, 'Enrolled'),
      ('Revenue', '₹12.4L', Icons.payments_outlined, 'This month'),
      ('Pending', '7', Icons.pending_outlined, 'Actions'),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: stats.map((s) => Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.cardBg,
          border: Border.all(color: tokens.cardBorder),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(color: tokens.shadowColor.withValues(alpha: 0.05), blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(s.$3, size: 15, color: tokens.primary),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: tokens.chipActiveBg, borderRadius: BorderRadius.circular(10)),
                child: Text(s.$4, style: TextStyle(color: tokens.chipActiveText, fontSize: 8)),
              ),
            ]),
            const SizedBox(height: 8),
            Text(s.$2,
                style: TextStyle(
                    color: tokens.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
            Text(s.$1, style: TextStyle(color: tokens.textSecondary, fontSize: 10)),
          ],
        ),
      )).toList(),
    );
  }
}

// ─── Table Preview ────────────────────────────────────────────────────────────

class _TablePreview extends StatelessWidget {
  const _TablePreview({required this.tokens});
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    const headers = ['School', 'City', 'Students', 'Status'];
    final rows = [
      ['Delhi Public School', 'Delhi', '2,400', 'Active'],
      ['Springfield High', 'Mumbai', '1,800', 'Active'],
      ["St. Mary's", 'Pune', '980', 'Trial'],
      ['Greenfield Academy', 'Chennai', '1,200', 'Active'],
      ['Sunrise School', 'Hyderabad', '560', 'Inactive'],
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: tokens.tableBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            decoration: BoxDecoration(
              color: tokens.tableHeaderBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: headers
                  .map((h) => Expanded(
                        child: Text(h,
                            style: TextStyle(
                                color: tokens.tableHeaderText,
                                fontWeight: FontWeight.w600,
                                fontSize: 10)),
                      ))
                  .toList(),
            ),
          ),
          // Data rows
          ...rows.asMap().entries.map((e) {
            final isEven = e.key.isEven;
            final row = e.value;
            final statusColor = row[3] == 'Active'
                ? tokens.successBg
                : row[3] == 'Trial'
                    ? tokens.warningBg
                    : tokens.errorBg;
            final statusText = row[3] == 'Active'
                ? tokens.successText
                : row[3] == 'Trial'
                    ? tokens.warningText
                    : tokens.errorText;
            return Container(
              color: isEven ? tokens.tableRowEvenBg : tokens.tableRowOddBg,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(row[0], style: TextStyle(color: tokens.textPrimary, fontSize: 10))),
                  Expanded(child: Text(row[1], style: TextStyle(color: tokens.textSecondary, fontSize: 10))),
                  Expanded(child: Text(row[2], style: TextStyle(color: tokens.textPrimary, fontSize: 10))),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: statusColor, borderRadius: BorderRadius.circular(10)),
                      child: Text(row[3], style: TextStyle(color: statusText, fontSize: 9)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Form Preview ─────────────────────────────────────────────────────────────

class _FormPreview extends StatelessWidget {
  const _FormPreview({required this.tokens});
  final AppThemeTokens tokens;

  Widget _field(String label, String hint) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: tokens.inputLabel, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: tokens.inputBg,
              border: Border.all(color: tokens.inputBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(hint, style: TextStyle(color: tokens.textHint, fontSize: 11)),
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.cardBg,
        border: Border.all(color: tokens.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add School',
              style: TextStyle(
                  color: tokens.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          _field('School Name', 'Enter school name...'),
          const SizedBox(height: 10),
          _field('City', 'Enter city...'),
          const SizedBox(height: 10),
          _field('Phone', '+91 XXXXXXXXXX'),
          const SizedBox(height: 14),
          Container(height: 1, color: tokens.divider),
          const SizedBox(height: 12),
          // Buttons
          Row(children: [
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: tokens.buttonSecondaryBg, borderRadius: BorderRadius.circular(6)),
              child:
                  Text('Cancel', style: TextStyle(color: tokens.buttonSecondaryText, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: tokens.buttonPrimaryBg, borderRadius: BorderRadius.circular(6)),
              child: Text('Save',
                  style: TextStyle(color: tokens.buttonPrimaryText, fontSize: 11)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: tokens.buttonDangerBg, borderRadius: BorderRadius.circular(6)),
              child: Text('Delete',
                  style: TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 14),
          // Status badges
          Wrap(spacing: 8, children: [
            _Badge('Active', tokens.successBg, tokens.successText),
            _Badge('Warning', tokens.warningBg, tokens.warningText),
            _Badge('Error', tokens.errorBg, tokens.errorText),
            _Badge('Info', tokens.infoBg, tokens.infoText),
          ]),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label, this.bg, this.fg);
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }
}
