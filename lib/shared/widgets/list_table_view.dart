// =============================================================================
// FILE: lib/shared/widgets/list_table_view.dart
// PURPOSE: Listing table with Sr. No, fixed header, scrollable body, infinite scroll,
//          row selection, and export support.
// =============================================================================

import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../../design_system/design_system.dart';

/// A listing table view with:
/// - Sr. No column
/// - Clear visual separation between header (th) and rows (tr)
/// - Fixed header; only body rows scroll
/// - Infinite scroll (15 records per page)
/// - Row selection for export
/// - Search + filters inline
class ListTableView extends StatelessWidget {
  const ListTableView({
    super.key,
    required this.columns,
    this.rows = const [],
    required this.columnWidths,
    this.itemCount,
    this.rowBuilder,
    this.sortableColumns,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
    this.selectedIds = const {},
    this.onSelectionChanged,
    this.showSrNo = true,
    this.rowIds,
  });

  final List<String> columns;
  final List<DataRow> rows;
  final List<double> columnWidths;
  /// When set with rowBuilder, enables lazy row building for faster load.
  final int? itemCount;
  final DataRow? Function(int index)? rowBuilder;
  final List<int>? sortableColumns;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending)? onSort;
  final bool isLoading;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final Set<String> selectedIds;
  final void Function(Set<String> ids)? onSelectionChanged;
  final bool showSrNo;
  /// Optional row IDs for selection (when onSelectionChanged is set).
  /// If provided, selectedIds/onSelectionChanged use these; else use index.
  final List<String>? rowIds;

  int get _rowCount => itemCount ?? rows.length;
  DataRow? _rowAt(int index) => rowBuilder != null ? rowBuilder!(index) : (index < rows.length ? rows[index] : null);

  @override
  Widget build(BuildContext context) {
    final effectiveColumns = showSrNo ? [AppStrings.tableSrNo, ...columns] : columns;
    final effectiveWidths = showSrNo ? [50.0, ...columnWidths] : columnWidths;
    final count = _rowCount;

    if (isLoading && count == 0) {
      return AppLoaderScreen();
    }

    if (count == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Builder(builder: (context) => Text(
            AppStrings.noRecordsFound,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          )),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = _totalWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: constraints.maxWidth,
              maxWidth: totalWidth > constraints.maxWidth ? totalWidth : constraints.maxWidth,
              minHeight: constraints.maxHeight,
              maxHeight: constraints.maxHeight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fixed header row
                _buildHeaderRow(context, effectiveColumns, effectiveWidths),
                // Header row separator
                Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.outlineVariant),
                // Scrollable body
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification &&
                          hasMore &&
                          onLoadMore != null &&
                          notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 100) {
                        onLoadMore!();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: true,
                      cacheExtent: 400,
                      itemCount: count + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= count) {
                          return const Padding(
                            padding: AppSpacing.paddingLg,
                            child: Center(child: SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                          );
                        }
                        final row = _rowAt(index);
                        if (row == null) return const SizedBox.shrink();
                        return RepaintBoundary(
                          child: _buildDataRow(context, index, row, effectiveWidths),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double get _totalWidth {
    final effectiveWidths = showSrNo ? [50.0, ...columnWidths] : columnWidths;
    return effectiveWidths.fold(0.0, (a, b) => a + b) + 32;
  }

  Widget _buildHeaderRow(
    BuildContext context,
    List<String> cols,
    List<double> widths,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final t = Theme.of(context).extension<AppThemeTokens>();
    final headerBg = t?.tableHeaderBg ?? (isDark ? AppColors.brandNavy900 : AppColors.lightSurfaceVar);
    final headerText = t?.tableHeaderText ?? (isDark ? AppColors.darkText : AppColors.lightText);
    final sortIconActive = t?.primary ?? (isDark ? AppColors.brandBlueLight : AppColors.brandBlue);
    final sortIconInactive = scheme.onSurfaceVariant;

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: _totalWidth),
      child: Container(
        color: headerBg,
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
        child: Row(
          children: List.generate(cols.length, (i) {
            final dataColIndex = showSrNo ? i - 1 : i;
            final isSortable = sortableColumns != null &&
                dataColIndex >= 0 &&
                sortableColumns!.contains(dataColIndex) &&
                onSort != null;
            final effectiveSortIndex = showSrNo && sortColumnIndex != null
                ? sortColumnIndex! + 1
                : sortColumnIndex;
            final isSorted = effectiveSortIndex == i;
            final label = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cols[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: headerText,
                    letterSpacing: 0.3,
                  ),
                ),
                if (isSortable)
                  GestureDetector(
                    onTap: () {
                      final col = showSrNo ? i - 1 : i;
                      onSort!(col, isSorted ? !sortAscending : true);
                    },
                    child: Icon(
                      isSorted
                          ? (sortAscending ? Icons.arrow_drop_up : Icons.arrow_drop_down)
                          : Icons.unfold_more,
                      size: 18,
                      color: isSorted ? sortIconActive : sortIconInactive,
                    ),
                  ),
              ],
            );
            return SizedBox(
              width: widths[i],
              child: Align(alignment: Alignment.centerLeft, child: label),
            );
          }),
        ),
      ),
    );
  }

  String _rowId(int index) {
    if (rowIds != null && index < rowIds!.length) return rowIds![index];
    return index.toString();
  }

  Widget _buildDataRow(
    BuildContext context,
    int index,
    DataRow row,
    List<double> widths,
  ) {
    final rowId = _rowId(index);
    final isSelected = selectedIds.contains(rowId);

    return InkWell(
      onTap: onSelectionChanged != null
          ? () {
              final next = Set<String>.from(selectedIds);
              if (next.contains(rowId)) {
                next.remove(rowId);
              } else {
                next.add(rowId);
              }
              onSelectionChanged!(next);
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : (index.isEven
                  ? (Theme.of(context).extension<AppThemeTokens>()?.tableRowEvenBg)
                  : (Theme.of(context).extension<AppThemeTokens>()?.tableRowOddBg)),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
        child: Row(
          children: [
            if (showSrNo) ...[
              SizedBox(
                width: widths[0],
                child: Align(alignment: Alignment.centerLeft, child: Text('${index + 1}')),
              ),
            ],
            ...List.generate(row.cells.length, (i) {
              final w = showSrNo ? widths[i + 1] : widths[i];
              return SizedBox(
                width: w,
                child: ClipRect(
                  child: Align(alignment: Alignment.centerLeft, child: row.cells[i].child),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
