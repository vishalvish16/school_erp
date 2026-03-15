import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/models/subscription_models.dart';
import '../../../../shared/widgets/reusable_data_table.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

class SubscriptionHistoryModal extends StatefulWidget {
  final List<SubscriptionHistoryModel> history;

  const SubscriptionHistoryModal({super.key, required this.history});

  @override
  State<SubscriptionHistoryModal> createState() => _SubscriptionHistoryModalState();
}

class _SubscriptionHistoryModalState extends State<SubscriptionHistoryModal> {
  int? _sortColumnIndex;
  bool _sortAscending = true;

  List<SubscriptionHistoryModel> _sortHistory(
    List<SubscriptionHistoryModel> list,
    int? columnIndex,
    bool ascending,
  ) {
    if (columnIndex == null || list.isEmpty) return list;
    final sorted = List<SubscriptionHistoryModel>.from(list);
    sorted.sort((a, b) {
      int cmp;
      switch (columnIndex) {
        case 0:
          cmp = a.planName.compareTo(b.planName);
          break;
        case 1:
          cmp = a.billingCycle.compareTo(b.billingCycle);
          break;
        case 2:
          cmp = a.startDate.compareTo(b.startDate);
          break;
        case 3:
          cmp = a.endDate.compareTo(b.endDate);
          break;
        case 4:
          cmp = a.status.compareTo(b.status);
          break;
        case 5:
          cmp = a.createdAt.compareTo(b.createdAt);
          break;
        default:
          return 0;
      }
      return ascending ? cmp : -cmp;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final sortedHistory = _sortHistory(
      widget.history,
      _sortColumnIndex,
      _sortAscending,
    );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl2),
      child: Container(
        width: MediaQuery.of(context).size.width > 900
            ? 800
            : MediaQuery.of(context).size.width * 0.95,
        padding: AppSpacing.paddingXl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    AppStrings.fullSubscriptionHistory,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Tooltip(
                  message: AppStrings.tooltipClose,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
            AppSpacing.vGapXl,
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.neutral400.withOpacity(0.2)),
                  borderRadius: AppRadius.brLg,
                ),
                child: SingleChildScrollView(
                  child: ReusableDataTable(
                    columns: const [
                      AppStrings.tablePlan,
                      AppStrings.tableBilling,
                      AppStrings.tableStartDate,
                      AppStrings.tableEndDate,
                      AppStrings.tableStatus,
                      AppStrings.tableCreatedAt,
                    ],
                    sortableColumns: const [0, 1, 2, 3, 4, 5],
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    onSort: (col, asc) => setState(() {
                      _sortColumnIndex = col;
                      _sortAscending = asc;
                    }),
                    rows: sortedHistory.map((h) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              h.planName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(Text(h.billingCycle)),
                          DataCell(
                            Text(
                              DateFormat('MMM dd, yyyy').format(h.startDate),
                            ),
                          ),
                          DataCell(
                            Text(DateFormat('MMM dd, yyyy').format(h.endDate)),
                          ),
                          DataCell(StatusBadge(status: h.status)),
                          DataCell(
                            Text(
                              DateFormat(
                                'MMM dd, yyyy HH:mm',
                              ).format(h.createdAt),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            AppSpacing.vGapLg,
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppStrings.totalRecords(widget.history.length),
                style: TextStyle(color: AppColors.neutral600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
