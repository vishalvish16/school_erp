// =============================================================================
// FILE: lib/features/super_admin/presentation/screens/super_admin_theme_screen.dart
// PURPOSE: Dynamic theme editor — split-panel color picker + live preview
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/app_toast.dart';
import 'super_admin_theme_preview.dart';

// ─── Token group definitions ──────────────────────────────────────────────────

const Map<String, List<String>> _kTokenGroups = {
  'Surface':    ['surfaceBg', 'cardBg', 'sidebarBg', 'topbarBg'],
  'Text':       ['textPrimary', 'textSecondary', 'textHint', 'textLink'],
  'Primary':    ['primary', 'primaryLight', 'primaryDark', 'onPrimary'],
  'Tables':     ['tableHeaderBg', 'tableHeaderText', 'tableRowEvenBg', 'tableRowOddBg', 'tableBorder', 'tableHoverBg'],
  'Inputs':     ['inputBg', 'inputBorder', 'inputFocusBorder', 'inputLabel'],
  'Buttons':    ['buttonPrimaryBg', 'buttonPrimaryText', 'buttonSecondaryBg', 'buttonSecondaryText', 'buttonDangerBg'],
  'Chips':      ['chipActiveBg', 'chipActiveText', 'chipInactiveBg'],
  'Status':     ['successBg', 'successText', 'warningBg', 'warningText', 'errorBg', 'errorText', 'infoBg', 'infoText'],
  'Navigation': ['navItemBg', 'navItemActiveBg', 'navItemText', 'navItemActiveText', 'navItemIcon', 'navItemActiveIcon'],
  'Borders':    ['divider', 'cardBorder', 'shadowColor'],
  'Shimmer':    ['shimmerBase', 'shimmerHighlight'],
};

const Map<String, String> _kTokenLabels = {
  'surfaceBg':          'Page Background',
  'cardBg':             'Card Background',
  'sidebarBg':          'Sidebar Background',
  'topbarBg':           'Topbar Background',
  'textPrimary':        'Primary Text',
  'textSecondary':      'Secondary Text',
  'textHint':           'Hint / Placeholder',
  'textLink':           'Link Text',
  'primary':            'Primary Color',
  'primaryLight':       'Primary Light',
  'primaryDark':        'Primary Dark',
  'onPrimary':          'On-Primary (button text)',
  'tableHeaderBg':      'Table Header Background',
  'tableHeaderText':    'Table Header Text',
  'tableRowEvenBg':     'Table Row (Even)',
  'tableRowOddBg':      'Table Row (Odd)',
  'tableBorder':        'Table Border',
  'tableHoverBg':       'Table Row Hover',
  'inputBg':            'Input Background',
  'inputBorder':        'Input Border',
  'inputFocusBorder':   'Input Focus Border',
  'inputLabel':         'Input Label',
  'buttonPrimaryBg':    'Primary Button Background',
  'buttonPrimaryText':  'Primary Button Text',
  'buttonSecondaryBg':  'Secondary Button Background',
  'buttonSecondaryText':'Secondary Button Text',
  'buttonDangerBg':     'Danger Button Background',
  'chipActiveBg':       'Active Chip Background',
  'chipActiveText':     'Active Chip Text',
  'chipInactiveBg':     'Inactive Chip Background',
  'successBg':          'Success Background',
  'successText':        'Success Text',
  'warningBg':          'Warning Background',
  'warningText':        'Warning Text',
  'errorBg':            'Error Background',
  'errorText':          'Error Text',
  'infoBg':             'Info Background',
  'infoText':           'Info Text',
  'navItemBg':          'Nav Item Background',
  'navItemActiveBg':    'Nav Item Active Background',
  'navItemText':        'Nav Item Text',
  'navItemActiveText':  'Nav Item Active Text',
  'navItemIcon':        'Nav Item Icon',
  'navItemActiveIcon':  'Nav Item Active Icon',
  'divider':            'Divider',
  'cardBorder':         'Card Border',
  'shadowColor':        'Shadow Color',
  'shimmerBase':        'Shimmer Base',
  'shimmerHighlight':   'Shimmer Highlight',
};

IconData _groupIcon(String group) {
  switch (group) {
    case 'Surface':    return Icons.layers_outlined;
    case 'Text':       return Icons.text_fields;
    case 'Primary':    return Icons.palette_outlined;
    case 'Tables':     return Icons.table_chart_outlined;
    case 'Inputs':     return Icons.input_outlined;
    case 'Buttons':    return Icons.smart_button_outlined;
    case 'Chips':      return Icons.label_outline;
    case 'Status':     return Icons.info_outline;
    case 'Navigation': return Icons.navigation_outlined;
    case 'Borders':    return Icons.border_all_outlined;
    case 'Shimmer':    return Icons.animation_outlined;
    default:           return Icons.circle_outlined;
  }
}

Color _tokenColor(AppThemeTokens t, String key) {
  switch (key) {
    case 'surfaceBg':          return t.surfaceBg;
    case 'cardBg':             return t.cardBg;
    case 'sidebarBg':          return t.sidebarBg;
    case 'topbarBg':           return t.topbarBg;
    case 'textPrimary':        return t.textPrimary;
    case 'textSecondary':      return t.textSecondary;
    case 'textHint':           return t.textHint;
    case 'textLink':           return t.textLink;
    case 'primary':            return t.primary;
    case 'primaryLight':       return t.primaryLight;
    case 'primaryDark':        return t.primaryDark;
    case 'onPrimary':          return t.onPrimary;
    case 'tableHeaderBg':      return t.tableHeaderBg;
    case 'tableHeaderText':    return t.tableHeaderText;
    case 'tableRowEvenBg':     return t.tableRowEvenBg;
    case 'tableRowOddBg':      return t.tableRowOddBg;
    case 'tableBorder':        return t.tableBorder;
    case 'tableHoverBg':       return t.tableHoverBg;
    case 'inputBg':            return t.inputBg;
    case 'inputBorder':        return t.inputBorder;
    case 'inputFocusBorder':   return t.inputFocusBorder;
    case 'inputLabel':         return t.inputLabel;
    case 'buttonPrimaryBg':    return t.buttonPrimaryBg;
    case 'buttonPrimaryText':  return t.buttonPrimaryText;
    case 'buttonSecondaryBg':  return t.buttonSecondaryBg;
    case 'buttonSecondaryText':return t.buttonSecondaryText;
    case 'buttonDangerBg':     return t.buttonDangerBg;
    case 'chipActiveBg':       return t.chipActiveBg;
    case 'chipActiveText':     return t.chipActiveText;
    case 'chipInactiveBg':     return t.chipInactiveBg;
    case 'successBg':          return t.successBg;
    case 'successText':        return t.successText;
    case 'warningBg':          return t.warningBg;
    case 'warningText':        return t.warningText;
    case 'errorBg':            return t.errorBg;
    case 'errorText':          return t.errorText;
    case 'infoBg':             return t.infoBg;
    case 'infoText':           return t.infoText;
    case 'navItemBg':          return t.navItemBg;
    case 'navItemActiveBg':    return t.navItemActiveBg;
    case 'navItemText':        return t.navItemText;
    case 'navItemActiveText':  return t.navItemActiveText;
    case 'navItemIcon':        return t.navItemIcon;
    case 'navItemActiveIcon':  return t.navItemActiveIcon;
    case 'divider':            return t.divider;
    case 'cardBorder':         return t.cardBorder;
    case 'shadowColor':        return t.shadowColor;
    case 'shimmerBase':        return t.shimmerBase;
    case 'shimmerHighlight':   return t.shimmerHighlight;
    default:                   return Colors.transparent;
  }
}

String _colorToHex(Color c) {
  final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b'.toUpperCase();
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class SuperAdminThemeScreen extends ConsumerStatefulWidget {
  const SuperAdminThemeScreen({super.key});

  @override
  ConsumerState<SuperAdminThemeScreen> createState() =>
      _SuperAdminThemeScreenState();
}

class _SuperAdminThemeScreenState extends ConsumerState<SuperAdminThemeScreen>
    with TickerProviderStateMixin {
  late final TabController _modeTab;   // Light / Dark
  late final TabController _previewTab; // Dashboard / Table / Form / Cards
  bool _editingLight = true;
  String _selectedPreset = 'Default';
  final Set<String> _expandedGroups = {'Surface', 'Primary', 'Tables'};

  @override
  void initState() {
    super.initState();
    _modeTab    = TabController(length: 2, vsync: this);
    _previewTab = TabController(length: 4, vsync: this);
    _modeTab.addListener(() {
      if (!_modeTab.indexIsChanging) {
        setState(() => _editingLight = _modeTab.index == 0);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeConfigProvider.notifier).loadTheme();
    });
  }

  @override
  void dispose() {
    _modeTab.dispose();
    _previewTab.dispose();
    super.dispose();
  }

  // ─── Color Picker Dialog ────────────────────────────────────────────────────

  Future<void> _openColorPicker(String tokenKey, Color initialColor) async {
    Color picked = initialColor;
    final hexCtrl = TextEditingController(text: _colorToHex(initialColor).replaceAll('#', ''));

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(_kTokenLabels[tokenKey] ?? tokenKey),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPicker(
                  pickerColor: picked,
                  onColorChanged: (c) {
                    setS(() => picked = c);
                    hexCtrl.text = _colorToHex(c).replaceAll('#', '');
                    ref.read(themeConfigProvider.notifier).updateToken(
                      isLight: _editingLight,
                      tokenKey: tokenKey,
                      color: c,
                    );
                  },
                  pickerAreaHeightPercent: 0.65,
                  enableAlpha: true,
                  labelTypes: const [ColorLabelType.hex, ColorLabelType.rgb],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: hexCtrl,
                  decoration: const InputDecoration(
                    prefixText: '#',
                    labelText: 'Hex Color',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Fa-f]')),
                    LengthLimitingTextInputFormatter(8),
                  ],
                  onChanged: (v) {
                    if (v.length == 6 || v.length == 8) {
                      try {
                        final hex = v.length == 6 ? 'FF$v' : v;
                        final c = Color(int.parse(hex, radix: 16));
                        setS(() { picked = c; });
                        ref.read(themeConfigProvider.notifier).updateToken(
                          isLight: _editingLight,
                          tokenKey: tokenKey,
                          color: c,
                        );
                      } catch (_) {}
                    }
                  },
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Revert live change on cancel
                ref.read(themeConfigProvider.notifier).updateToken(
                  isLight: _editingLight,
                  tokenKey: tokenKey,
                  color: initialColor,
                );
                Navigator.pop(ctx);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Save as Custom Preset Dialog ───────────────────────────────────────────

  Future<void> _showSaveAsDialog() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Preset'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Preset name',
            hintText: 'e.g. My School Theme',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name == null || name.trim().isEmpty) return;
    await ref.read(themeConfigProvider.notifier).saveAsCustomPreset(name);
    setState(() => _selectedPreset = name.trim());
    if (mounted) {
      AppToast.showSuccess(context, 'Preset "${name.trim()}" saved!');
    }
  }

  // ─── Apply to Portals Dialog ────────────────────────────────────────────────

  void _showApplyDialog() {
    const portals = {
      'school_admin': 'School Admin',
      'group_admin':  'Group Admin',
      'staff':        'Staff / Clerk',
      'teacher':      'Teacher',
      'parent':       'Parent',
      'student':      'Student',
      'driver':       'Driver',
    };
    final selected = <String>{...portals.keys};

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Apply Theme to Portals'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select portals to receive this theme configuration:'),
                const SizedBox(height: 12),
                ...portals.entries.map((e) => CheckboxListTile(
                  dense: true,
                  title: Text(e.value),
                  value: selected.contains(e.key),
                  onChanged: (v) => setS(() {
                    if (v == true) { selected.add(e.key); }
                    else { selected.remove(e.key); }
                  }),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            Consumer(builder: (ctx2, ref2, _) {
              final applying = ref2.watch(themeConfigProvider).isApplying;
              return FilledButton(
                onPressed: applying || selected.isEmpty
                    ? null
                    : () async {
                        await ref2.read(themeConfigProvider.notifier).applyToPortals(selected.toList());
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          AppToast.showSuccess(context, 'Theme applied to selected portals!');
                        }
                      },
                child: applying
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Apply'),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state  = ref.watch(themeConfigProvider);
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.sizeOf(context).width >= 1100;

    // Listen for success/error toasts
    ref.listen<ThemeConfigState>(themeConfigProvider, (prev, next) {
      if (next.saveSuccess && !(prev?.saveSuccess ?? false)) {
        AppToast.showSuccess(context, 'Theme saved successfully!');
      }
      if (next.applySuccess && !(prev?.applySuccess ?? false)) {
        AppToast.showSuccess(context, 'Theme applied to selected portals!');
      }
      if (next.error != null && next.error != prev?.error) {
        AppToast.showError(context, next.error!);
      }
    });

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(state, scheme),
          _buildModeTabs(),
          Expanded(
            child: isWide ? _buildWideLayout(state) : _buildNarrowLayout(state),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeConfigState state, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/super-admin/dashboard'),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme Settings',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Customize colors for every portal element',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
          const Spacer(),
          // Preset selector — built-in + custom presets
          Consumer(builder: (ctx, ref2, _) {
            final allPresets = ref2.watch(themeConfigProvider).allPresets;
            final customKeys = ref2.watch(themeConfigProvider).customPresets.keys.toSet();
            // Ensure selected value exists in the list
            final validValue = allPresets.containsKey(_selectedPreset)
                ? _selectedPreset
                : allPresets.keys.first;
            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: validValue,
                borderRadius: BorderRadius.circular(8),
                items: allPresets.keys.map((k) {
                  final isCustom = customKeys.contains(k);
                  return DropdownMenuItem(
                    value: k,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCustom) ...[
                          const Icon(Icons.bookmark, size: 13, color: Colors.amber),
                          const SizedBox(width: 4),
                        ],
                        Text(k),
                        if (isCustom) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              ref2.read(themeConfigProvider.notifier)
                                  .deleteCustomPreset(k);
                              if (_selectedPreset == k) {
                                setState(() => _selectedPreset = 'Default');
                              }
                            },
                            child: const Icon(Icons.close, size: 13),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _selectedPreset = v);
                  ref2.read(themeConfigProvider.notifier).applyPreset(v);
                },
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: () {
              ref.read(themeConfigProvider.notifier).resetToDefaults();
              setState(() => _selectedPreset = 'Default');
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset'),
          ),
          OutlinedButton.icon(
            onPressed: _showSaveAsDialog,
            icon: const Icon(Icons.bookmark_add_outlined, size: 16),
            label: const Text('Save as...'),
          ),
          OutlinedButton.icon(
            onPressed: _showApplyDialog,
            icon: const Icon(Icons.people_alt_outlined, size: 16),
            label: const Text('Apply to Portals'),
          ),
          FilledButton.icon(
            onPressed: state.isSaving
                ? null
                : () => ref.read(themeConfigProvider.notifier).saveTheme(),
            icon: state.isSaving
                ? const SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 16),
            label: const Text('Save Theme'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: TabBar(
        controller: _modeTab,
        tabs: const [
          Tab(icon: Icon(Icons.light_mode_outlined), text: 'Light Theme'),
          Tab(icon: Icon(Icons.dark_mode_outlined), text: 'Dark Theme'),
        ],
      ),
    );
  }

  Widget _buildWideLayout(ThemeConfigState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 420, child: _buildTokenEditor(state)),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(child: _buildPreviewPanel()),
      ],
    );
  }

  Widget _buildNarrowLayout(ThemeConfigState state) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [Tab(text: 'Editor'), Tab(text: 'Preview')]),
          Expanded(
            child: TabBarView(
              children: [_buildTokenEditor(state), _buildPreviewPanel()],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Token Editor (left panel) ───────────────────────────────────────────────

  Widget _buildTokenEditor(ThemeConfigState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final tokens = _editingLight ? state.lightTokens : state.darkTokens;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: _kTokenGroups.entries.map((group) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            initiallyExpanded: _expandedGroups.contains(group.key),
            onExpansionChanged: (v) => setState(() {
              if (v) { _expandedGroups.add(group.key); }
              else { _expandedGroups.remove(group.key); }
            }),
            leading: Icon(_groupIcon(group.key), size: 18),
            title: Text(group.key,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            children: group.value.map((tokenKey) {
              final color = _tokenColor(tokens, tokenKey);
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                leading: GestureDetector(
                  onTap: () => _openColorPicker(tokenKey, color),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black12),
                    ),
                  ),
                ),
                title: Text(
                  _kTokenLabels[tokenKey] ?? tokenKey,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  _colorToHex(color),
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () => _openColorPicker(tokenKey, color),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  // ─── Preview Panel (right panel) ─────────────────────────────────────────────

  Widget _buildPreviewPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: TabBar(
            controller: _previewTab,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Dashboard'),
              Tab(text: 'Table'),
              Tab(text: 'Form'),
              Tab(text: 'Cards'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _previewTab,
            children: [
              SuperAdminThemePreview(key: const ValueKey('preview_dashboard'), isLight: _editingLight, previewMode: ThemePreviewMode.dashboard),
              SuperAdminThemePreview(key: const ValueKey('preview_table'),     isLight: _editingLight, previewMode: ThemePreviewMode.table),
              SuperAdminThemePreview(key: const ValueKey('preview_form'),      isLight: _editingLight, previewMode: ThemePreviewMode.form),
              SuperAdminThemePreview(key: const ValueKey('preview_cards'),     isLight: _editingLight, previewMode: ThemePreviewMode.cards),
            ],
          ),
        ),
      ],
    );
  }
}
