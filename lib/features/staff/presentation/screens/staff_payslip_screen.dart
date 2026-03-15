// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_payslip_screen.dart
// PURPOSE: Staff portal — payslip placeholder (payroll module coming soon).
// =============================================================================

import 'package:flutter/material.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

class StaffPayslipScreen extends StatelessWidget {
  const StaffPayslipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthName = months[now.month - 1];

    return Scaffold(
      backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long,
                size: 80,
                color: AppColors.neutral400,
              ),
              AppSpacing.vGapXl,
              Text(
                'Payslip',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              AppSpacing.vGapSm,
              Text(
                'Payroll module is under development.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapXl2,

              // Preview of what it will look like
              Opacity(
                opacity: 0.35,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('$monthName ${now.year}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const Text('Monthly Salary Slip',
                                      style: TextStyle(
                                          color: AppColors.neutral400,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: AppColors.neutral200,
                                borderRadius:
                                    AppRadius.brMd,
                              ),
                              child: const Text('Preview',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.neutral400)),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _previewRow('Basic Salary', '—'),
                        _previewRow('HRA', '—'),
                        _previewRow('Allowances', '—'),
                        const Divider(height: 16),
                        _previewRow('Gross Pay', '—',
                            bold: true),
                        _previewRow('Deductions', '—'),
                        const Divider(height: 16),
                        _previewRow('Net Pay', '—',
                            bold: true),
                      ],
                    ),
                  ),
                ),
              ),

              AppSpacing.vGapXl,
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning500.withValues(alpha: 0.1),
                  borderRadius: AppRadius.brMd,
                  border: Border.all(
                      color: AppColors.warning500.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.construction,
                        size: 18, color: AppColors.warning500),
                    AppSpacing.hGapSm,
                    Text(
                      'Coming in the next release',
                      style: TextStyle(
                          color: AppColors.warning500, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewRow(String label, String value,
      {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: AppColors.neutral400)),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: bold
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: AppColors.neutral400)),
        ],
      ),
    );
  }
}
