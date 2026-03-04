import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/subscription_models.dart';
import '../../../../shared/widgets/reusable_data_table.dart';

class SubscriptionHistoryModal extends StatelessWidget {
  final List<SubscriptionHistoryModel> history;

  const SubscriptionHistoryModal({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width > 900
            ? 800
            : MediaQuery.of(context).size.width * 0.95,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Full Subscription History',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: ReusableDataTable(
                    columns: const [
                      'Plan',
                      'Billing',
                      'Start Date',
                      'End Date',
                      'Status',
                      'Created At',
                    ],
                    rows: history.map((h) {
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
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total Records: ${history.length}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
