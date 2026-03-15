// =============================================================================
// FILE: lib/features/school_admin/presentation/screens/school_admin_profile_screen.dart
// =============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/api_config.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../design_system/design_system.dart';
import '../providers/school_admin_profile_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

class SchoolAdminProfileScreen extends ConsumerWidget {
  const SchoolAdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(schoolAdminProfileProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: EdgeInsets.all(isWide ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.profile,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      ref.invalidate(schoolAdminProfileProvider),
                  icon: const Icon(Icons.refresh),
                  tooltip: AppStrings.refresh,
                ),
              ],
            ),
            AppSpacing.vGapLg,
            Expanded(
              child: asyncProfile.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error),
                      AppSpacing.vGapLg,
                      Text(err.toString().replaceAll('Exception: ', '')),
                      AppSpacing.vGapLg,
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(schoolAdminProfileProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (profile) => SingleChildScrollView(
                  child: isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _UserInfoCard(
                                profile: profile,
                                onEdit: () =>
                                    _showEditUserDialog(context, ref, profile),
                              ),
                            ),
                            AppSpacing.hGapLg,
                            Expanded(
                              child: _SchoolInfoCard(
                                profile: profile,
                                onEdit: () => _showEditSchoolDialog(
                                    context, ref, profile),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _UserInfoCard(
                              profile: profile,
                              onEdit: () =>
                                  _showEditUserDialog(context, ref, profile),
                            ),
                            AppSpacing.vGapLg,
                            _SchoolInfoCard(
                              profile: profile,
                              onEdit: () =>
                                  _showEditSchoolDialog(context, ref, profile),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUserDialog(BuildContext context, WidgetRef ref,
      Map<String, dynamic> profile) async {
    final user = profile['user'] as Map<String, dynamic>? ?? {};
    final firstCtrl =
        TextEditingController(text: user['first_name'] as String? ?? user['firstName'] as String? ?? '');
    final lastCtrl =
        TextEditingController(text: user['last_name'] as String? ?? user['lastName'] as String? ?? '');
    final phoneCtrl =
        TextEditingController(text: user['phone'] as String? ?? '');
    String? avatarBase64;
    final avatarUrl = user['avatar_url'] as String? ?? user['avatarUrl'] as String?;
    bool isSaving = false;

    String avatarDisplayUrl() {
      if (avatarBase64 != null) return '';
      if (avatarUrl == null || avatarUrl.isEmpty) return '';
      return avatarUrl.startsWith('http')
          ? avatarUrl
          : '${ApiConfig.baseUrl}$avatarUrl';
    }

    ImageProvider? avatarImageProvider() {
      if (avatarBase64 != null) {
        try {
          final base64Data = avatarBase64!.replaceFirst(RegExp(r'data:image/\w+;base64,'), '');
          final bytes = base64Decode(base64Data);
          return MemoryImage(bytes);
        } catch (_) {
          return null;
        }
      }
      final url = avatarDisplayUrl();
      if (url.isNotEmpty) return NetworkImage(url);
      return null;
    }

    Future<void> pickImage(void Function(void Function()) setSt) async {
      try {
        final picker = ImagePicker();
        final xfile = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 400,
          maxHeight: 400,
          imageQuality: 85,
        );
        if (xfile == null || !context.mounted) return;
        final bytes = await xfile.readAsBytes();
        final base64 = base64Encode(bytes);
        final mime = xfile.mimeType ?? 'image/jpeg';
        setSt(() => avatarBase64 = 'data:$mime;base64,$base64');
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.error(context, 'Failed to pick image: $e');
        }
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(AppStrings.editPersonalInfo),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () => pickImage(setSt),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: _accent.withValues(alpha: 0.2),
                          backgroundImage: avatarImageProvider(),
                          child: avatarImageProvider() == null
                              ? Text(
                                  (firstCtrl.text.isNotEmpty && lastCtrl.text.isNotEmpty)
                                      ? '${firstCtrl.text[0]}${lastCtrl.text[0]}'
                                      : 'SA',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _accent,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: _accent,
                            child: Icon(
                              avatarBase64 != null ? Icons.check : Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                AppSpacing.vGapSm,
                Center(
                  child: Text(
                    AppStrings.tapToChangePhoto,
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                AppSpacing.vGapLg,
                TextField(
                  controller: firstCtrl,
                  decoration: InputDecoration(
                      labelText: AppStrings.firstName,
                      border: const OutlineInputBorder()),
                ),
                AppSpacing.vGapMd,
                TextField(
                  controller: lastCtrl,
                  decoration: InputDecoration(
                      labelText: AppStrings.lastName, border: const OutlineInputBorder()),
                ),
                AppSpacing.vGapMd,
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                      labelText: AppStrings.phone, border: const OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppStrings.cancel)),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setSt(() => isSaving = true);
                      try {
                        final body = <String, dynamic>{
                          'firstName': firstCtrl.text.trim(),
                          'lastName': lastCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                        };
                        if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
                          body['avatar_base64'] = avatarBase64;
                        }
                        await ref
                            .read(schoolAdminServiceProvider)
                            .updateUserProfile(body);
                        ref.invalidate(schoolAdminProfileProvider);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      } catch (e) {
                        if (ctx.mounted) {
                          AppSnackbar.error(ctx, e.toString().replaceAll('Exception: ', ''));
                        }
                      }
                      setSt(() => isSaving = false);
                    },
              style: FilledButton.styleFrom(backgroundColor: _accent),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditSchoolDialog(BuildContext context, WidgetRef ref,
      Map<String, dynamic> profile) async {
    final school = profile['school'] as Map<String, dynamic>? ?? {};
    final nameCtrl =
        TextEditingController(text: school['name'] as String? ?? '');
    final phoneCtrl =
        TextEditingController(text: school['phone'] as String? ?? '');
    final emailCtrl =
        TextEditingController(text: school['email'] as String? ?? '');
    final addressCtrl =
        TextEditingController(text: school['address'] as String? ?? '');
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: Text(AppStrings.editSchoolInfo),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                      labelText: AppStrings.schoolName,
                      border: const OutlineInputBorder()),
                ),
                AppSpacing.vGapMd,
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                      labelText: AppStrings.phone, border: const OutlineInputBorder()),
                ),
                AppSpacing.vGapMd,
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                      labelText: AppStrings.email, border: const OutlineInputBorder()),
                ),
                AppSpacing.vGapMd,
                TextField(
                  controller: addressCtrl,
                  decoration: InputDecoration(
                      labelText: AppStrings.address, border: const OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(AppStrings.cancel)),
            FilledButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setSt(() => isSaving = true);
                      try {
                        await ref
                            .read(schoolAdminServiceProvider)
                            .updateSchoolProfile({
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                        });
                        ref.invalidate(schoolAdminProfileProvider);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                      } catch (e) {
                        if (ctx.mounted) {
                          AppSnackbar.error(ctx, e.toString().replaceAll('Exception: ', ''));
                        }
                      }
                      setSt(() => isSaving = false);
                    },
              style: FilledButton.styleFrom(backgroundColor: _accent),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoCard extends StatelessWidget {
  const _UserInfoCard({required this.profile, required this.onEdit});
  final Map<String, dynamic> profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final user = profile['user'] as Map<String, dynamic>? ?? {};
    final firstName = user['first_name'] as String? ?? user['firstName'] as String? ?? '';
    final lastName = user['last_name'] as String? ?? user['lastName'] as String? ?? '';
    final email = user['email'] as String? ?? '';
    final phone = user['phone'] as String? ?? '-';
    final role = user['role'] as String? ?? 'SCHOOL_ADMIN';
    final avatarUrl = user['avatar_url'] as String? ?? user['avatarUrl'] as String?;
    final avatarDisplayUrl = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? (avatarUrl.startsWith('http') ? avatarUrl : '${ApiConfig.baseUrl}$avatarUrl')
        : '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: _accent.withValues(alpha: 0.2),
                  backgroundImage: avatarDisplayUrl.isNotEmpty
                      ? NetworkImage(avatarDisplayUrl)
                      : null,
                  child: avatarDisplayUrl.isEmpty
                      ? Text(
                          firstName.isNotEmpty && lastName.isNotEmpty
                              ? '${firstName[0]}${lastName[0]}'
                              : 'SA',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _accent,
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
                        '$firstName $lastName',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        role,
                        style: TextStyle(
                          color: _accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: AppStrings.edit,
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(label: AppStrings.email, value: email),
            _InfoRow(label: AppStrings.phone, value: phone),
          ],
        ),
      ),
    );
  }
}

class _SchoolInfoCard extends StatelessWidget {
  const _SchoolInfoCard({required this.profile, required this.onEdit});
  final Map<String, dynamic> profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final school = profile['school'] as Map<String, dynamic>? ?? {};
    final name = school['name'] as String? ?? '-';
    final phone = school['phone'] as String? ?? '-';
    final email = school['email'] as String? ?? '-';
    final address = school['address'] as String? ?? '-';
    final city = school['city'] as String? ?? '';
    final state = school['state'] as String? ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: _accent, size: 28),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: AppStrings.editSchoolInfo,
                ),
              ],
            ),
            const Divider(height: 24),
            _InfoRow(label: AppStrings.phone, value: phone),
            _InfoRow(label: AppStrings.email, value: email),
            _InfoRow(label: AppStrings.address, value: address),
            if (city.isNotEmpty || state.isNotEmpty)
              _InfoRow(
                  label: AppStrings.location,
                  value: [city, state]
                      .where((s) => s.isNotEmpty)
                      .join(', ')),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
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
            width: 90,
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
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
