// =============================================================================
// FILE: lib/widgets/common/plan_icon_picker.dart
// PURPOSE: Reusable icon picker widget for plan create/edit dialogs.
//          Shows a tappable preview that opens a grid of curated plan emojis.
// =============================================================================

import 'package:flutter/material.dart';
import '../../design_system/design_system.dart';
import '../../core/constants/app_strings.dart';

/// Curated list of plan-appropriate emojis.
const List<String> _kPlanIcons = [
  '\u{1F4E6}', // 📦
  '\u{1F680}', // 🚀
  '\u2B50',    // ⭐
  '\u{1F48E}', // 💎
  '\u{1F3C6}', // 🏆
  '\u{1F393}', // 🎓
  '\u{1F4DA}', // 📚
  '\u{1F525}', // 🔥
  '\u2728',    // ✨
  '\u{1F4A1}', // 💡
  '\u{1F3AF}', // 🎯
  '\u{1F451}', // 👑
  '\u{1F31F}', // 🌟
  '\u{1F4CA}', // 📊
  '\u{1F381}', // 🎁
  '\u{1F511}', // 🔑
  '\u26A1',    // ⚡
  '\u{1F308}', // 🌈
  '\u{1F4AB}', // 💫
  '\u{1F947}', // 🥇
  '\u{1F3C5}', // 🏅
  '\u{1F3AA}', // 🎪
  '\u{1F3EB}', // 🏫
  '\u{1F396}', // 🎖️
];

/// A tappable icon preview that opens a bottom sheet grid of curated emojis.
///
/// Usage:
/// ```dart
/// PlanIconPicker(
///   selectedIcon: _selectedIcon,
///   onSelected: (icon) => setState(() => _selectedIcon = icon),
/// )
/// ```
class PlanIconPicker extends StatelessWidget {
  const PlanIconPicker({
    super.key,
    required this.selectedIcon,
    required this.onSelected,
  });

  final String selectedIcon;
  final ValueChanged<String> onSelected;

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: AppRadius.bottomSheetShape,
      builder: (_) => _PlanIconGrid(
        selectedIcon: selectedIcon,
        onSelected: (icon) {
          onSelected(icon);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.planIconLabel,
          style: AppTextStyles.bodySm(color: scheme.onSurfaceVariant),
        ),
        AppSpacing.vGapSm,
        InkWell(
          onTap: () => _openPicker(context),
          borderRadius: AppRadius.brLg,
          child: Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest
                  .withValues(alpha: AppOpacity.hover),
              borderRadius: AppRadius.brLg,
              border: Border.all(
                color: scheme.outline.withValues(alpha: AppOpacity.medium),
                width: AppBorderWidth.thin,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: AppSpacing.xl4,
                  height: AppSpacing.xl4,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: AppRadius.brMd,
                    border: Border.all(
                      color: scheme.primary,
                      width: AppBorderWidth.thick,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    selectedIcon,
                    style: AppTextStyles.h2(),
                  ),
                ),
                AppSpacing.hGapMd,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedIcon,
                      style: AppTextStyles.h6(color: scheme.onSurface),
                    ),
                    Text(
                      AppStrings.tapToChangeIcon,
                      style: AppTextStyles.bodySm(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Internal grid shown inside the bottom sheet.
class _PlanIconGrid extends StatelessWidget {
  const _PlanIconGrid({
    required this.selectedIcon,
    required this.onSelected,
  });

  final String selectedIcon;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: AppSpacing.dialogPadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.selectPlanIcon,
            style: AppTextStyles.h5(color: scheme.onSurface),
          ),
          AppSpacing.vGapLg,
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
            ),
            itemCount: _kPlanIcons.length,
            itemBuilder: (context, index) {
              final icon = _kPlanIcons[index];
              final isSelected = icon == selectedIcon;

              return InkWell(
                onTap: () => onSelected(icon),
                borderRadius: AppRadius.brMd,
                child: AnimatedContainer(
                  duration: AppDuration.fast,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest
                            .withValues(alpha: AppOpacity.hover),
                    borderRadius: AppRadius.brMd,
                    border: Border.all(
                      color: isSelected
                          ? scheme.primary
                          : scheme.outline
                              .withValues(alpha: AppOpacity.divider),
                      width: isSelected
                          ? AppBorderWidth.thick
                          : AppBorderWidth.thin,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    icon,
                    style: AppTextStyles.h3(),
                  ),
                ),
              );
            },
          ),
          AppSpacing.vGapMd,
        ],
      ),
    );
  }
}
