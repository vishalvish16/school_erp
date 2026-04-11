import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_theme_tokens.dart';
import '../../design_system/design_system.dart';

class ReusableDataTable extends StatelessWidget {
  final List<String> columns;
  final List<DataRow> rows;
  final bool isLoading;
  /// Fixed widths per column. When provided, prevents layout shift when cell content changes.
  final List<double>? columnWidths;
  /// Column indices that support sorting. When provided, headers show sort icon and are tappable.
  final List<int>? sortableColumns;
  /// Currently sorted column index (0-based), or null if no sort.
  final int? sortColumnIndex;
  /// true = ascending, false = descending.
  final bool sortAscending;
  /// Called when user taps a sortable column header. (columnIndex, ascending).
  final void Function(int columnIndex, bool ascending)? onSort;

  const ReusableDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.columnWidths,
    this.sortableColumns,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return AppLoaderScreen();
    }

    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            AppStrings.noRecordsFound,
            style: TextStyle(color: AppColors.neutral400, fontSize: 16),
          ),
        ),
      );
    }

    final widths = columnWidths;
    final hasWidths = widths != null && widths.length == columns.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final t = Theme.of(context).extension<AppThemeTokens>();

        // Apply even/odd row colors from theme tokens — DataTable has no
        // built-in alternating row support so we inject color per-DataRow.
        final themedRows = List.generate(rows.length, (i) {
          final row = rows[i];
          // Only override color if the caller hasn't set one already.
          if (row.color != null) return row;
          final rowBg = i.isEven ? t?.tableRowEvenBg : t?.tableRowOddBg;
          return DataRow(
            key: row.key,
            selected: row.selected,
            onSelectChanged: row.onSelectChanged,
            onLongPress: row.onLongPress,
            color: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected) ||
                  states.contains(WidgetState.hovered)) {
                return t?.tableHoverBg;
              }
              return rowBg;
            }),
            cells: row.cells,
          );
        });

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              headingRowColor: WidgetStateProperty.resolveWith((states) {
                return t?.tableHeaderBg ?? AppColors.neutral100;
              }),
              columns: List.generate(columns.length, (i) {
                final isSortable = sortableColumns != null &&
                    sortableColumns!.contains(i) &&
                    onSort != null;
                final isSorted = sortColumnIndex == i;
                final label = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      columns[i],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isSortable)
                      Icon(
                        isSorted
                            ? (sortAscending
                                ? Icons.arrow_drop_up
                                : Icons.arrow_drop_down)
                            : Icons.unfold_more,
                        size: 18,
                        color: isSorted ? AppColors.secondary500 : AppColors.neutral400,
                      ),
                  ],
                );
                return DataColumn(
                  label: hasWidths
                      ? SizedBox(
                          width: widths[i],
                          child: label,
                        )
                      : label,
                  onSort: isSortable
                      ? (columnIndex, ascending) =>
                          onSort!(columnIndex, ascending)
                      : null,
                );
              }),
              rows: themedRows,
            ),
          ),
        );
      },
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({required this.status, super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<AppThemeTokens>();
    Color bgColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bgColor   = t?.successBg   ?? AppColors.success100;
        textColor = t?.successText ?? AppColors.success700;
        break;
      case 'SUSPENDED':
        bgColor   = t?.errorBg   ?? AppColors.error100;
        textColor = t?.errorText ?? AppColors.error700;
        break;
      default:
        bgColor   = t?.chipInactiveBg ?? AppColors.neutral200;
        textColor = t?.textSecondary  ?? AppColors.neutral800;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.brLg,
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
