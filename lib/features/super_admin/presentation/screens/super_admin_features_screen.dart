// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_features_screen.dart
// PURPOSE: Super Admin platform feature flags
// =============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';
import '../../../../utils/download_file.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../../../design_system/tokens/app_colors.dart';

class SuperAdminFeaturesScreen extends ConsumerStatefulWidget {
  const SuperAdminFeaturesScreen({super.key});

  @override
  ConsumerState<SuperAdminFeaturesScreen> createState() =>
      _SuperAdminFeaturesScreenState();
}

class _SuperAdminFeaturesScreenState extends ConsumerState<SuperAdminFeaturesScreen> {
  bool _loading = true;
  String? _error;
  List<SuperAdminPlatformFeatureModel> _features = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final service = ref.read(superAdminServiceProvider);
      final list = await service.getPlatformFeatures();
      if (mounted) {
        setState(() {
          _features = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _loading = false;
          _features = [];
        });
      }
    }
  }

  Future<void> _toggle(String key, bool value) async {
    final newValue = !value;
    if (key.toLowerCase().contains('maintenance') && newValue) {
      final ok = await AppDialogs.confirm(
        context,
        title: AppStrings.enableMaintenanceMode,
        message: 'All schools, parents, and staff will see a maintenance page.',
        confirmLabel: AppStrings.enableMaintenance,
        isDestructive: true,
      );
      if (!ok || !mounted) return;
    }
    if (key.toLowerCase().contains('sms') && !newValue) {
      final ok = await AppDialogs.confirm(
        context,
        title: AppStrings.turnOffSmsGateway,
        message: 'Turning off SMS will disable all OTP logins.',
        confirmLabel: AppStrings.turnOff,
        isDestructive: true,
      );
      if (!ok || !mounted) return;
    }
    final prev = value;
    setState(() {
      _features = _features.map((f) =>
        f.featureKey == key ? SuperAdminPlatformFeatureModel(
          id: f.id,
          featureKey: f.featureKey,
          featureName: f.featureName,
          category: f.category,
          description: f.description,
          isEnabled: newValue,
        ) : f,
      ).toList();
    });
    try {
      final service = ref.read(superAdminServiceProvider);
      await service.togglePlatformFeature(key, newValue);
      if (mounted) {
        AppSnackbar.success(context, '${newValue ? "Enabled" : "Disabled"} $key');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _features = _features.map((f) =>
            f.featureKey == key ? SuperAdminPlatformFeatureModel(
              id: f.id,
              featureKey: f.featureKey,
              featureName: f.featureName,
              category: f.category,
              description: f.description,
              isEnabled: prev,
            ) : f,
          ).toList();
        });
        AppSnackbar.error(context, 'Failed: ${e.toString()}');
      }
    }
  }

  Future<void> _exportFeatureFlags(String format) async {
    if (_features.isEmpty) return;
    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      String content;
      String filename;
      String mimeType;
      if (format == 'csv') {
        content = _toCsv(_features);
        filename = 'feature_flags_$timestamp.csv';
        mimeType = 'text/csv';
      } else {
        content = const JsonEncoder.withIndent('  ').convert(
          _features.map((f) => f.toJson()).toList(),
        );
        filename = 'feature_flags_$timestamp.json';
        mimeType = 'application/json';
      }
      final message = await downloadFile(content, filename, mimeType);
      if (mounted) {
        AppSnackbar.success(context, message);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Export failed: ${e.toString()}');
      }
    }
  }

  String _toCsv(List<SuperAdminPlatformFeatureModel> features) {
    String escape(String s) => '"${s.replaceAll('"', '""')}"';
    const header = 'id,feature_key,feature_name,category,description,is_enabled';
    final rows = features.map((f) {
      return [
        escape(f.id),
        escape(f.featureKey),
        escape(f.featureName),
        escape(f.category),
        escape(f.description ?? ''),
        f.isEnabled.toString(),
      ].join(',');
    });
    return [header, ...rows].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final platformFeatures = _features.where((f) => f.category != 'system').toList();
    final systemFeatures = _features.where((f) => f.category == 'system').toList();
    final isNarrow = MediaQuery.of(context).size.width < 600;
    final padding = isNarrow ? 16.0 : 24.0;

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                final header = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.globalFeatureFlags,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    AppSpacing.vGapXs,
                    Text(
                      'Platform-wide switches · Overrides per-school settings when OFF',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                );
                final exportBtn = PopupMenuButton<String>(
                  enabled: _features.isNotEmpty,
                  onSelected: _exportFeatureFlags,
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'json',
                      child: Row(
                        children: [
                          Icon(Icons.code, size: 20),
                          AppSpacing.hGapMd,
                          Text(AppStrings.exportAsJson),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'csv',
                      child: Row(
                        children: [
                          Icon(Icons.table_chart, size: 20),
                          AppSpacing.hGapMd,
                          Text(AppStrings.exportAsCsv),
                        ],
                      ),
                    ),
                  ],
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_download, size: 18),
                        AppSpacing.hGapSm,
                        Text(AppStrings.exportState),
                        AppSpacing.hGapXs,
                        Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                );
                return isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          header,
                          AppSpacing.vGapMd,
                          exportBtn,
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: header),
                          exportBtn,
                        ],
                      );
              },
            ),
            AppSpacing.vGapXl,
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(48),
                child: CircularProgressIndicator(),
              ))
            else if (_error != null)
              Card(
                child: Padding(
                  padding: AppSpacing.paddingXl,
                  child: Column(
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                      AppSpacing.vGapLg,
                      Text(_error!, textAlign: TextAlign.center),
                      AppSpacing.vGapLg,
                      FilledButton(onPressed: _load, child: const Text(AppStrings.retry)),
                    ],
                  ),
                ),
              )
            else if (_features.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Icon(Icons.flag_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                      AppSpacing.vGapLg,
                      Text(AppStrings.noPlatformFeatures, style: Theme.of(context).textTheme.titleMedium),
                      AppSpacing.vGapSm,
                      FilledButton(onPressed: _load, child: const Text(AppStrings.retry)),
                    ],
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 800;
                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildFeatureCard(AppStrings.platformWideFeatures, platformFeatures, Icons.public)),
                            AppSpacing.hGapLg,
                            Expanded(child: _buildFeatureCard(AppStrings.systemMaintenance, systemFeatures, Icons.settings)),
                          ],
                        )
                      : Column(
                          children: [
                            _buildFeatureCard(AppStrings.platformWideFeatures, platformFeatures, Icons.public),
                            AppSpacing.vGapLg,
                            _buildFeatureCard(AppStrings.systemMaintenance, systemFeatures, Icons.settings),
                          ],
                        );
                },
              ),
            if (!_loading && _error == null && _features.isNotEmpty) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: Theme.of(context).colorScheme.primary),
                      AppSpacing.hGapMd,
                      Expanded(
                        child: Text(
                          'Features enabled per plan are managed in Plans & Pricing. School-level overrides are in each school\'s manage modal.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(String title, List<SuperAdminPlatformFeatureModel> features, IconData icon) {
    if (features.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
                AppSpacing.hGapSm,
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (title == 'Platform-Wide Features')
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.warning500.withValues(alpha: 0.1),
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: AppColors.warning500.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'Disabling a platform feature overrides all school-level settings globally.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f.featureName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (f.description != null && f.description!.isNotEmpty)
                          Text(
                            f.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                  ),
                  Switch(
                    value: f.isEnabled,
                    onChanged: (_) => _toggle(f.featureKey, f.isEnabled),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
