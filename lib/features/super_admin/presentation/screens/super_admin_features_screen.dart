// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_features_screen.dart
// PURPOSE: Super Admin platform feature flags
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/super_admin_service.dart';
import '../../../../models/super_admin/super_admin_models.dart';

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
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Enable Maintenance Mode?'),
          content: const Text(
            'All schools, parents, and staff will see a maintenance page.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Enable Maintenance')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    if (key.toLowerCase().contains('sms') && !newValue) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Turn off SMS Gateway?'),
          content: const Text(
            'Turning off SMS will disable all OTP logins.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Turn Off')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${newValue ? "Enabled" : "Disabled"} $key')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feature Flags',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ))
          else if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
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
                    const SizedBox(height: 16),
                    Text('No platform features configured', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  itemCount: _features.length,
                  itemBuilder: (_, i) {
                    final f = _features[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: SwitchListTile(
                        title: Text(f.featureName),
                        subtitle: f.description != null ? Text(f.description!) : null,
                        secondary: Icon(
                          f.category == 'system' ? Icons.settings : Icons.extension,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        value: f.isEnabled,
                        onChanged: (v) => _toggle(f.featureKey, f.isEnabled),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
