// =============================================================================
// FILE: lib/features/student/presentation/screens/student_documents_screen.dart
// PURPOSE: Documents screen for the Student portal.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../design_system/design_system.dart';
import '../../../../core/constants/app_strings.dart';
import '../../data/student_providers.dart';

const Color _accent = AppColors.info500;

class StudentDocumentsScreen extends ConsumerWidget {
  const StudentDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDocs = ref.watch(studentDocumentsProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(studentDocumentsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.studentDocumentsTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            AppSpacing.vGapXl,
            asyncDocs.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(64),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Card(
                child: Padding(
                  padding: AppSpacing.paddingXl,
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                      AppSpacing.vGapLg,
                      Text(err.toString().replaceAll('Exception: ', '')),
                      AppSpacing.vGapLg,
                      FilledButton(
                        onPressed: () => ref.invalidate(studentDocumentsProvider),
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (docs) {
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                        AppSpacing.vGapLg,
                        Text(
                          AppStrings.noDocumentsAvailable,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => AppSpacing.vGapSm,
                  itemBuilder: (ctx, i) {
                    final d = docs[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: _accent.withValues(alpha: 0.15),
                          child: const Icon(Icons.description, color: _accent),
                        ),
                        title: Text(d.documentName),
                        subtitle: Text(
                          '${d.documentType}${d.fileSizeKb != null ? ' • ${d.fileSizeKb} KB' : ''}${d.verified ? ' • Verified' : ''}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => _openUrl(d.fileUrl),
                          tooltip: AppStrings.openDocument,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
