import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';

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
      return const Center(child: CircularProgressIndicator());
    }

    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            AppStrings.noRecordsFound,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    final widths = columnWidths;
    final hasWidths = widths != null && widths.length == columns.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              sortColumnIndex: sortColumnIndex,
              sortAscending: sortAscending,
              headingRowColor: WidgetStateProperty.resolveWith(
                (states) => Colors.grey.shade100,
              ),
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
                        color: isSorted ? Colors.blue : Colors.grey,
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
              rows: rows,
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
    Color bgColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        break;
      case 'SUSPENDED':
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
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
