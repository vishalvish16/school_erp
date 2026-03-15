// =============================================================================
// FILE: lib/features/staff/presentation/screens/staff_student_detail_screen.dart
// PURPOSE: Read-only student profile + payment history for Staff/Clerk portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/staff_service.dart';
import '../../../../models/staff/staff_student_model.dart';
import '../../../../models/staff/staff_payment_model.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.secondary400;

// Per-student providers (family)
final _studentDetailProvider =
    FutureProvider.autoDispose.family<StaffStudentModel, String>((ref, id) {
  return ref.read(staffServiceProvider).getStudentById(id);
});

final _studentPaymentsProvider =
    FutureProvider.autoDispose.family<List<StaffPaymentModel>, String>(
        (ref, studentId) async {
  final svc = ref.read(staffServiceProvider);
  final response = await svc.getFeePayments(studentId: studentId, limit: 50);
  final dataWrapper = response['data'];
  List<dynamic> rawList = [];
  if (dataWrapper is Map) {
    rawList = (dataWrapper['data'] as List?) ?? [];
  } else if (dataWrapper is List) {
    rawList = dataWrapper;
  }
  return rawList
      .map((e) => StaffPaymentModel.fromJson(e as Map<String, dynamic>))
      .toList();
});

class StaffStudentDetailScreen extends ConsumerWidget {
  const StaffStudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStudent = ref.watch(_studentDetailProvider(studentId));
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Student Profile'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: asyncStudent.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error),
              AppSpacing.vGapMd,
              Text(err.toString().replaceAll('Exception: ', '')),
              AppSpacing.vGapMd,
              FilledButton(
                onPressed: () =>
                    ref.invalidate(_studentDetailProvider(studentId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (student) => SingleChildScrollView(
          padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(student: student),
              const SizedBox(height: 20),
              _InfoCard(student: student),
              const SizedBox(height: 20),
              _ParentCard(student: student),
              const SizedBox(height: 20),
              _PaymentHistorySection(studentId: studentId),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Profile Header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.student});

  final StaffStudentModel student;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: _accent.withValues(alpha: 0.15),
              backgroundImage: student.photoUrl != null
                  ? NetworkImage(student.photoUrl!)
                  : null,
              child: student.photoUrl == null
                  ? Text(
                      student.firstName.isNotEmpty
                          ? student.firstName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 24,
                        color: _accent,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  AppSpacing.vGapXs,
                  Text(
                    student.admissionNo,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (student.className != null) ...[
                        _Tag(
                            text:
                                '${student.className}${student.sectionName != null ? ' ${student.sectionName}' : ''}',
                            color: _accent),
                        const SizedBox(width: 6),
                      ],
                      _Tag(
                        text: student.status,
                        color: student.status == 'ACTIVE'
                            ? AppColors.success500
                            : AppColors.warning500,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.brLg,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.student});

  final StaffStudentModel student;

  @override
  Widget build(BuildContext context) {
    final dob = student.dateOfBirth;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal Info',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            _InfoRow('Gender', student.gender),
            _InfoRow(
                'Date of Birth',
                '${months[dob.month - 1]} ${dob.day}, ${dob.year}'),
            if (student.bloodGroup != null)
              _InfoRow('Blood Group', student.bloodGroup!),
            if (student.phone != null)
              _InfoRow('Phone', student.phone!),
            if (student.email != null)
              _InfoRow('Email', student.email!),
            if (student.address != null)
              _InfoRow('Address', student.address!),
            if (student.rollNo != null)
              _InfoRow('Roll No', '${student.rollNo}'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ── Parent Card ───────────────────────────────────────────────────────────────

class _ParentCard extends StatelessWidget {
  const _ParentCard({required this.student});

  final StaffStudentModel student;

  @override
  Widget build(BuildContext context) {
    if (student.parentName == null && student.parentPhone == null) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parent / Guardian',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 16),
            if (student.parentName != null)
              _InfoRow('Name', student.parentName!),
            if (student.parentPhone != null)
              _InfoRow('Phone', student.parentPhone!),
          ],
        ),
      ),
    );
  }
}

// ── Payment History ───────────────────────────────────────────────────────────

class _PaymentHistorySection extends ConsumerWidget {
  const _PaymentHistorySection({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPayments =
        ref.watch(_studentPaymentsProvider(studentId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment History',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        AppSpacing.vGapSm,
        asyncPayments.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (err, _) => Text(
            err.toString().replaceAll('Exception: ', ''),
            style: TextStyle(
                color: Theme.of(context).colorScheme.error),
          ),
          data: (payments) => payments.isEmpty
              ? const Center(
                  child: Padding(
                    padding: AppSpacing.paddingXl,
                    child: Text('No payments recorded',
                        style: TextStyle(color: AppColors.neutral400)),
                  ),
                )
              : Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: payments.length,
                    separatorBuilder:
                        (context, index) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final p = payments[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.success500.withValues(alpha: 0.15),
                          child: const Icon(Icons.receipt,
                              size: 16, color: AppColors.success500),
                        ),
                        title: Text(p.feeHead,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          '${p.receiptNo}  •  ${p.paymentMode}  •  ${p.academicYear}',
                          style:
                              Theme.of(ctx).textTheme.bodySmall,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${p.amount.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.success500,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              _fmt(p.paymentDate),
                              style:
                                  Theme.of(ctx).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  String _fmt(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
