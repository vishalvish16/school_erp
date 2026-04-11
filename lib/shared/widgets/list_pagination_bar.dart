// =============================================================================
// FILE: lib/shared/widgets/list_pagination_bar.dart
// PURPOSE: Responsive pagination footer for list/table screens — avoids horizontal
//          overflow on narrow viewports by stacking controls and wrapping buttons.
// =============================================================================

import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../design_system/design_system.dart';

/// Pagination bar used under list tables. Wide: single row. Narrow: stacked + wrap.
class ListPaginationBar extends StatelessWidget {
  const ListPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalEntries,
    required this.pageSize,
    required this.pageSizeOptions,
    required this.onPageSizeChanged,
    required this.onGoToPage,
    /// Viewports narrower than this use compact (stacked) layout.
    this.compactBreakpoint = 600,
  });

  final int currentPage;
  final int totalPages;
  final int totalEntries;
  final int pageSize;
  final List<int> pageSizeOptions;
  final ValueChanged<int?> onPageSizeChanged;
  final ValueChanged<int> onGoToPage;
  final double compactBreakpoint;

  int get _start =>
      totalEntries == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;

  int get _end => (currentPage * pageSize).clamp(0, totalEntries);

  int get _effectivePageSize {
    if (pageSizeOptions.isEmpty) return pageSize;
    return pageSizeOptions.contains(pageSize)
        ? pageSize
        : pageSizeOptions.first;
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width < compactBreakpoint;
    final cs = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodySmall!;
    final mutedStyle = textStyle.copyWith(color: cs.onSurfaceVariant);

    Widget pageButton(String label, {required int page, bool active = false}) {
      final enabled =
          page != currentPage && page >= 1 && page <= totalPages;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: active ? cs.primary : Colors.transparent,
          borderRadius: AppRadius.brSm,
          child: InkWell(
            borderRadius: AppRadius.brSm,
            onTap: enabled ? () => onGoToPage(page) : null,
            child: Container(
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              alignment: Alignment.center,
              padding: AppSpacing.paddingHSm,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? cs.onPrimary
                      : enabled
                          ? cs.onSurface
                          : cs.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),
      );
    }

    List<Widget> pageNumbers() {
      final pages = <Widget>[];
      const maxVisible = 5;
      int rangeStart =
          (currentPage - (maxVisible ~/ 2)).clamp(1, totalPages);
      int rangeEnd =
          (rangeStart + maxVisible - 1).clamp(1, totalPages);
      if (rangeEnd - rangeStart < maxVisible - 1) {
        rangeStart =
            (rangeEnd - maxVisible + 1).clamp(1, totalPages);
      }
      for (int i = rangeStart; i <= rangeEnd; i++) {
        pages.add(pageButton('$i', page: i, active: i == currentPage));
      }
      return pages;
    }

    final showingText = Text(
      AppStrings.showingEntries(_start, _end, totalEntries),
      style: mutedStyle,
    );

    final pageSizeDropdown = Container(
      height: 28,
      padding: AppSpacing.paddingHSm,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.neutral400),
        borderRadius: AppRadius.brXs,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _effectivePageSize,
          isDense: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: textStyle.copyWith(color: cs.onSurface),
          items: pageSizeOptions
              .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
              .toList(),
          onChanged: onPageSizeChanged,
        ),
      ),
    );

    final pageSizeControl = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(AppStrings.show, style: mutedStyle),
        const SizedBox(width: 6),
        pageSizeDropdown,
        const SizedBox(width: 6),
        Text(AppStrings.entries, style: mutedStyle),
      ],
    );

    final navButtonWidgets = <Widget>[
      pageButton('First', page: 1),
      pageButton('Previous', page: currentPage - 1),
      ...pageNumbers(),
      pageButton('Next', page: currentPage + 1),
      pageButton('Last', page: totalPages),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.neutral300)),
      ),
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                showingText,
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [pageSizeControl],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 2,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: navButtonWidgets,
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                showingText,
                AppSpacing.hGapXl,
                pageSizeControl,
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: navButtonWidgets,
                ),
              ],
            ),
    );
  }
}
