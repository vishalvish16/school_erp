import 'package:flutter/material.dart';

class ReusableDataTable extends StatelessWidget {
  final List<String> columns;
  final List<DataRow> rows;
  final bool isLoading;

  const ReusableDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
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
            'No records found',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: WidgetStateProperty.resolveWith(
                (states) => Colors.grey.shade100,
              ),
              columns: columns
                  .map(
                    (col) => DataColumn(
                      label: Text(
                        col,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                  .toList(),
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
