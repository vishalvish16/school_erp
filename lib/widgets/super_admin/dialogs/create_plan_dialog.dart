// =============================================================================
// FILE: lib/widgets/super_admin/dialogs/create_plan_dialog.dart
// PURPOSE: Create or edit plan dialog — professional redesign
//          Gradient header · Pill tabs · 2-col form · Live pricing · Feature cards
// =============================================================================

import 'package:flutter/material.dart';
import '../../../design_system/design_system.dart';
import '../../../core/constants/app_strings.dart';
import '../../common/searchable_dropdown_form_field.dart';
import '../../common/plan_icon_picker.dart';
import '../../../../models/super_admin/super_admin_models.dart';

// ── Feature catalogue ─────────────────────────────────────────────────────────

class _FeatureMeta {
  const _FeatureMeta(this.key, this.label, this.desc, this.icon);
  final String key;
  final String label;
  final String desc;
  final IconData icon;
}

class _FeatureCategory {
  const _FeatureCategory({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.features,
  });
  final String label;
  final String subtitle;
  final IconData icon;
  final List<_FeatureMeta> features;
}

const _kCategories = <_FeatureCategory>[
  _FeatureCategory(
    label: 'Core Modules',
    subtitle: 'Essential daily operations',
    icon: Icons.school_outlined,
    features: [
      _FeatureMeta('attendance', 'Attendance', 'Daily student/staff tracking',
          Icons.how_to_reg_outlined),
      _FeatureMeta('fees', 'Fees & Finance', 'Fee collection & receipts',
          Icons.account_balance_wallet_outlined),
      _FeatureMeta('exams', 'Examinations', 'Marks, results & report cards',
          Icons.assignment_outlined),
      _FeatureMeta('timetable', 'Timetable', 'Weekly schedule builder',
          Icons.calendar_month_outlined),
      _FeatureMeta('certificates', 'Certificates', 'Achievement certificates',
          Icons.workspace_premium_outlined),
    ],
  ),
  _FeatureCategory(
    label: 'Smart Features',
    subtitle: 'AI-powered insights & tools',
    icon: Icons.auto_awesome_outlined,
    features: [
      _FeatureMeta('ai_intelligence', 'AI Intelligence',
          'Smart insights & predictions', Icons.psychology_outlined),
      _FeatureMeta('reports', 'Reports', 'Analytics & data exports',
          Icons.bar_chart_outlined),
    ],
  ),
  _FeatureCategory(
    label: 'Infrastructure',
    subtitle: 'Connectivity & integrations',
    icon: Icons.hub_outlined,
    features: [
      _FeatureMeta('parent_app', 'Parent App', 'Parent portal & alerts',
          Icons.family_restroom_outlined),
      _FeatureMeta('chat_system', 'Chat System', 'Staff & parent messaging',
          Icons.chat_bubble_outline),
      _FeatureMeta('online_payments', 'Online Payments',
          'Razorpay/UPI integration', Icons.payment_outlined),
      _FeatureMeta('rfid_attendance', 'RFID Attendance',
          'Hardware-based tracking', Icons.nfc_outlined),
    ],
  ),
  _FeatureCategory(
    label: 'Academic Tools',
    subtitle: 'Resources & campus services',
    icon: Icons.menu_book_outlined,
    features: [
      _FeatureMeta('library', 'Library', 'Books issue & return',
          Icons.local_library_outlined),
      _FeatureMeta('transport', 'Transport', 'Buses, routes & assignment',
          Icons.directions_bus_outlined),
      _FeatureMeta('gps_transport', 'GPS Tracking',
          'Real-time vehicle tracking', Icons.location_on_outlined),
      _FeatureMeta(
          'hostel', 'Hostel', 'Boarding student management', Icons.hotel_outlined),
    ],
  ),
];

const _kCategoryColors = <Color>[
  AppColors.secondary500,
  AppColors.primary500,
  AppColors.warning500,
  AppColors.success500,
];

// ── Gradient presets per support level ───────────────────────────────────────

LinearGradient _headerGradient(String supportLevel) {
  switch (supportLevel) {
    case 'priority':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
      );
    case 'dedicated':
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD97706), Color(0xFFEF4444)],
      );
    default: // standard
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1D4ED8), Color(0xFF4F46E5)],
      );
  }
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class CreateEditPlanDialog extends StatefulWidget {
  const CreateEditPlanDialog({
    super.key,
    this.plan,
    required this.onSave,
  });

  final SuperAdminPlanModel? plan;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  State<CreateEditPlanDialog> createState() => _CreateEditPlanDialogState();
}

class _CreateEditPlanDialogState extends State<CreateEditPlanDialog>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _slugController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _maxStudentsController = TextEditingController();

  late final TabController _tabController;

  String _selectedIcon = '\u{1F4E6}';
  String _status = 'active';
  String _supportLevel = 'standard';
  final Map<String, bool> _features = {
    for (final cat in _kCategories)
      for (final f in cat.features) f.key: false,
  };
  bool _submitting = false;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _activeTab = _tabController.index);
      }
    });
    final p = widget.plan;
    if (p != null) {
      _nameController.text = p.name;
      _slugController.text = p.slug;
      _priceController.text = p.pricePerStudent.toStringAsFixed(0);
      _descController.text = p.description ?? '';
      _maxStudentsController.text = p.maxStudents?.toString() ?? '';
      _selectedIcon = p.iconEmoji ?? '\u{1F4E6}';
      _status = p.status ?? 'active';
      _supportLevel = p.supportLevel ?? 'standard';
      for (final entry in p.features.entries) {
        if (_features.containsKey(entry.key)) {
          _features[entry.key] = entry.value;
        }
      }
    }
    _nameController.addListener(_syncSlug);
    _priceController.addListener(() => setState(() {}));
    _maxStudentsController.addListener(() => setState(() {}));
  }

  void _syncSlug() {
    if (widget.plan != null) return;
    final slug = _slugFromName(_nameController.text);
    if (_slugController.text.isEmpty ||
        _slugController.text == _slugFromName(_slugController.text)) {
      _slugController.text = slug;
    }
  }

  String _slugFromName(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  @override
  void dispose() {
    _nameController.removeListener(_syncSlug);
    _nameController.dispose();
    _slugController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _maxStudentsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _submit({bool asDraft = false}) async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text);
    if (name.isEmpty) {
      AppSnackbar.warning(context, AppStrings.nameRequired);
      return;
    }
    if (price == null || price < 0) {
      AppSnackbar.warning(context, AppStrings.validPriceRequired);
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.onSave({
        'name': name,
        'slug': _slugController.text.trim().isEmpty
            ? _slugFromName(name)
            : _slugController.text.trim(),
        'price_per_student': price,
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        'max_students': _maxStudentsController.text.trim().isEmpty
            ? null
            : int.tryParse(_maxStudentsController.text),
        'support_level': _supportLevel,
        'status': asDraft ? 'draft' : _status,
        'icon_emoji': _selectedIcon,
        'features': _features,
      });
      if (mounted) {
        Navigator.of(context).pop(true);
        AppSnackbar.success(
          context,
          widget.plan == null
              ? AppStrings.planCreatedSuccess
              : AppStrings.planUpdatedSuccess,
        );
      }
    } catch (e) {
      if (mounted) AppSnackbar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  int _totalEnabledFeatures() =>
      _features.values.where((v) => v).length;

  int _enabledCount(_FeatureCategory cat) =>
      cat.features.where((f) => _features[f.key] == true).length;

  void _setCategoryAll(_FeatureCategory cat, bool value) {
    setState(() {
      for (final f in cat.features) {
        _features[f.key] = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final price = double.tryParse(_priceController.text) ?? 0;
    final maxStudents = int.tryParse(_maxStudentsController.text) ?? 500;
    final estMrr = price * maxStudents;
    final gradient = _headerGradient(_supportLevel);
    final totalFeatures = _features.length;
    final enabledFeatures = _totalEnabledFeatures();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gradient header ───────────────────────────────────────────────
          _DialogHeader(
            isEdit: widget.plan != null,
            selectedIcon: _selectedIcon,
            planName: _nameController.text.trim().isEmpty
                ? (widget.plan == null ? 'New Plan' : widget.plan!.name)
                : _nameController.text.trim(),
            gradient: gradient,
            supportLevel: _supportLevel,
            price: price,
            estMrr: estMrr,
            enabledFeatures: enabledFeatures,
            totalFeatures: totalFeatures,
            onClose: () => Navigator.of(context).pop(),
          ),

          // ── Pill tab switcher ─────────────────────────────────────────────
          _PillTabBar(
            activeIndex: _activeTab,
            onTap: (i) {
              _tabController.animateTo(i);
              setState(() => _activeTab = i);
            },
            tabs: const ['Details', 'Features'],
            accentColor: gradient.colors.first,
          ),

          // ── Tab content ───────────────────────────────────────────────────
          SizedBox(
            height: 420,
            child: TabBarView(
              controller: _tabController,
              children: [
                _DetailsTab(
                  nameController: _nameController,
                  slugController: _slugController,
                  priceController: _priceController,
                  descController: _descController,
                  maxStudentsController: _maxStudentsController,
                  selectedIcon: _selectedIcon,
                  status: _status,
                  supportLevel: _supportLevel,
                  price: price,
                  estMrr: estMrr,
                  onIconSelected: (v) => setState(() => _selectedIcon = v),
                  onStatusChanged: (v) =>
                      setState(() => _status = v ?? 'active'),
                  onSupportChanged: (v) =>
                      setState(() => _supportLevel = v ?? 'standard'),
                ),
                _FeaturesTab(
                  categories: _kCategories,
                  features: _features,
                  enabledCount: _enabledCount,
                  onToggle: (key, v) => setState(() => _features[key] = v),
                  onSetCategoryAll: _setCategoryAll,
                ),
              ],
            ),
          ),

          // ── Actions bar ───────────────────────────────────────────────────
          _ActionsBar(
            isEdit: widget.plan != null,
            submitting: _submitting,
            accentColor: gradient.colors.first,
            onCancel: () => Navigator.of(context).pop(),
            onDraft: widget.plan == null ? () => _submit(asDraft: true) : null,
            onSave: () => _submit(),
          ),
        ],
      ),
    );
  }
}

// ── Gradient dialog header ────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.isEdit,
    required this.selectedIcon,
    required this.planName,
    required this.gradient,
    required this.supportLevel,
    required this.price,
    required this.estMrr,
    required this.enabledFeatures,
    required this.totalFeatures,
    required this.onClose,
  });

  final bool isEdit;
  final String selectedIcon;
  final String planName;
  final LinearGradient gradient;
  final String supportLevel;
  final double price;
  final double estMrr;
  final int enabledFeatures;
  final int totalFeatures;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final supportLabel = supportLevel[0].toUpperCase() +
        supportLevel.substring(1).toLowerCase();

    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: [
          // Decorative background circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(selectedIcon,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),

                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Plan' : 'Create New Plan',
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        planName,
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      // Stat pills
                      Wrap(
                        spacing: 8,
                        children: [
                          _HeaderPill(
                            icon: Icons.currency_rupee,
                            label: price > 0
                                ? '₹${price.toStringAsFixed(0)}/student'
                                : 'Set price',
                          ),
                          _HeaderPill(
                            icon: Icons.support_agent_outlined,
                            label: '$supportLabel support',
                          ),
                          _HeaderPill(
                            icon: Icons.extension_outlined,
                            label: '$enabledFeatures/$totalFeatures features',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Close button
                IconButton(
                  onPressed: onClose,
                  style: IconButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pill tab switcher ─────────────────────────────────────────────────────────

class _PillTabBar extends StatelessWidget {
  const _PillTabBar({
    required this.activeIndex,
    required this.onTap,
    required this.tabs,
    required this.accentColor,
  });

  final int activeIndex;
  final void Function(int) onTap;
  final List<String> tabs;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: isDark ? scheme.surface : const Color(0xFFF6F8FB),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.07)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: List.generate(tabs.length, (i) {
            final isActive = i == activeIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isActive ? accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : scheme.onSurface.withValues(alpha: 0.55),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── Details tab ───────────────────────────────────────────────────────────────

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({
    required this.nameController,
    required this.slugController,
    required this.priceController,
    required this.descController,
    required this.maxStudentsController,
    required this.selectedIcon,
    required this.status,
    required this.supportLevel,
    required this.price,
    required this.estMrr,
    required this.onIconSelected,
    required this.onStatusChanged,
    required this.onSupportChanged,
  });

  final TextEditingController nameController;
  final TextEditingController slugController;
  final TextEditingController priceController;
  final TextEditingController descController;
  final TextEditingController maxStudentsController;
  final String selectedIcon;
  final String status;
  final String supportLevel;
  final double price;
  final double estMrr;
  final ValueChanged<String> onIconSelected;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onSupportChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? scheme.surface : const Color(0xFFF6F8FB);

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section: Plan identity ──────────────────────────────────────
            _SectionLabel(label: 'Plan Identity'),
            const SizedBox(height: 10),
            _FieldCard(
              children: [
                _FormRow(
                  child: TextFormField(
                    controller: nameController,
                    decoration: _inputDeco(
                      context,
                      label: 'Plan Name',
                      hint: 'e.g. Basic, Standard, Premium',
                      icon: Icons.label_outline,
                    ),
                  ),
                ),
                _FieldDivider(),
                _FormRow(
                  child: TextFormField(
                    controller: slugController,
                    decoration: _inputDeco(
                      context,
                      label: 'Slug (URL key)',
                      hint: 'auto-generated',
                      icon: Icons.link_outlined,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Section: Pricing ────────────────────────────────────────────
            _SectionLabel(label: 'Pricing & Limits'),
            const SizedBox(height: 10),
            _FieldCard(
              children: [
                // Price + MRR preview row
                _FormRow(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: priceController,
                        decoration: _inputDeco(
                          context,
                          label: 'Price per Student (₹)',
                          hint: '0',
                          icon: Icons.currency_rupee,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      if (price > 0) ...[
                        const SizedBox(height: 10),
                        _PricingPreviewBar(
                          price: price,
                          estMrr: estMrr,
                          maxStudents: int.tryParse(
                                  maxStudentsController.text) ??
                              500,
                        ),
                      ],
                    ],
                  ),
                ),
                _FieldDivider(),
                _FormRow(
                  child: TextFormField(
                    controller: maxStudentsController,
                    decoration: _inputDeco(
                      context,
                      label: 'Max Students (optional)',
                      hint: 'No limit',
                      icon: Icons.group_outlined,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Section: Plan settings ──────────────────────────────────────
            _SectionLabel(label: 'Plan Settings'),
            const SizedBox(height: 10),
            _FieldCard(
              children: [
                _FormRow(
                  child: SearchableDropdownFormField<String>.valueItems(
                    value: supportLevel,
                    valueItems: const [
                      MapEntry('standard', 'Standard'),
                      MapEntry('priority', 'Priority'),
                      MapEntry('dedicated', 'Dedicated'),
                    ],
                    decoration: _inputDeco(
                      context,
                      label: 'Support Level',
                      icon: Icons.support_agent_outlined,
                    ),
                    onChanged: onSupportChanged,
                  ),
                ),
                _FieldDivider(),
                _FormRow(
                  child: SearchableDropdownFormField<String>.valueItems(
                    value: status,
                    valueItems: const [
                      MapEntry('active', 'Active'),
                      MapEntry('draft', 'Draft'),
                      MapEntry('inactive', 'Inactive'),
                    ],
                    decoration: _inputDeco(
                      context,
                      label: 'Status',
                      icon: Icons.toggle_on_outlined,
                    ),
                    onChanged: onStatusChanged,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Section: Description & icon ─────────────────────────────────
            _SectionLabel(label: 'Description & Icon'),
            const SizedBox(height: 10),
            _FieldCard(
              children: [
                _FormRow(
                  child: TextFormField(
                    controller: descController,
                    decoration: _inputDeco(
                      context,
                      label: 'Description (optional)',
                      hint: 'Brief plan description for school admins…',
                      icon: Icons.notes_outlined,
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                ),
                _FieldDivider(),
                _FormRow(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Plan Icon',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: scheme.onSurface.withValues(alpha: 0.55),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      PlanIconPicker(
                        selectedIcon: selectedIcon,
                        onSelected: onIconSelected,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _inputDeco(
  BuildContext context, {
  required String label,
  String? hint,
  required IconData icon,
  bool alignLabelWithHint = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    hintText: hint,
    alignLabelWithHint: alignLabelWithHint,
    prefixIcon: Icon(icon, size: 18,
        color: scheme.primary.withValues(alpha: 0.7)),
    filled: false,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
    labelStyle: TextStyle(
      fontSize: 13,
      color: scheme.onSurface.withValues(alpha: 0.55),
    ),
    hintStyle: TextStyle(
      fontSize: 13,
      color: scheme.onSurface.withValues(alpha: 0.35),
    ),
  );
}

// ── Pricing preview bar ───────────────────────────────────────────────────────

class _PricingPreviewBar extends StatelessWidget {
  const _PricingPreviewBar({
    required this.price,
    required this.estMrr,
    required this.maxStudents,
  });

  final double price;
  final double estMrr;
  final int maxStudents;

  String _formatAmount(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(1)}K';
    return '₹${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary500.withValues(alpha: 0.08),
            AppColors.primary500.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.secondary500.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.trending_up_rounded,
              size: 16, color: AppColors.success500),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 12.5, color: scheme.onSurface.withValues(alpha: 0.7)),
                children: [
                  const TextSpan(text: 'Est. MRR at '),
                  TextSpan(
                    text: '$maxStudents students ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const TextSpan(text: '→ '),
                  TextSpan(
                    text: _formatAmount(estMrr),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.success600,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(
                    text: '/school/month',
                    style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared form primitives ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.45),
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Column(children: children),
    );
  }
}

class _FormRow extends StatelessWidget {
  const _FormRow({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: child,
    );
  }
}

class _FieldDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: scheme.outline.withValues(alpha: 0.15),
    );
  }
}

// ── Features tab ──────────────────────────────────────────────────────────────

class _FeaturesTab extends StatelessWidget {
  const _FeaturesTab({
    required this.categories,
    required this.features,
    required this.enabledCount,
    required this.onToggle,
    required this.onSetCategoryAll,
  });

  final List<_FeatureCategory> categories;
  final Map<String, bool> features;
  final int Function(_FeatureCategory) enabledCount;
  final void Function(String key, bool value) onToggle;
  final void Function(_FeatureCategory cat, bool value) onSetCategoryAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: isDark ? scheme.surface : const Color(0xFFF6F8FB),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          children: [
            for (var i = 0; i < categories.length; i++) ...[
              _CategoryCard(
                category: categories[i],
                color: _kCategoryColors[i],
                features: features,
                enabled: enabledCount(categories[i]),
                onToggle: onToggle,
                onSetAll: (v) => onSetCategoryAll(categories[i], v),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.color,
    required this.features,
    required this.enabled,
    required this.onToggle,
    required this.onSetAll,
  });

  final _FeatureCategory category;
  final Color color;
  final Map<String, bool> features;
  final int enabled;
  final void Function(String key, bool value) onToggle;
  final void Function(bool value) onSetAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = category.features.length;
    final allOn = enabled == total;
    final allOff = enabled == 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Category header ───────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: isDark ? 0.2 : 0.08),
                  color.withValues(alpha: isDark ? 0.1 : 0.03),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(category.icon, color: color, size: 17),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.label,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.1,
                        ),
                      ),
                      Text(
                        category.subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Count badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: enabled > 0
                        ? color.withValues(alpha: 0.15)
                        : scheme.outlineVariant.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$enabled/$total',
                    style: textTheme.bodySmall?.copyWith(
                      color: enabled > 0 ? color : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Compact All On / All Off buttons
                _QuickToggleBtn(
                    label: 'All On',
                    active: allOn,
                    color: color,
                    onTap: () => onSetAll(true)),
                const SizedBox(width: 5),
                _QuickToggleBtn(
                    label: 'All Off',
                    active: allOff,
                    color: AppColors.error500,
                    onTap: () => onSetAll(false)),
              ],
            ),
          ),

          // ── Feature rows ──────────────────────────────────────────────────
          for (int i = 0; i < category.features.length; i++) ...[
            _FeatureRow(
              meta: category.features[i],
              enabled: features[category.features[i].key] ?? false,
              color: color,
              onToggle: (v) => onToggle(category.features[i].key, v),
            ),
            if (i < category.features.length - 1)
              Divider(
                height: 1,
                indent: 14,
                endIndent: 14,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
          ],
        ],
      ),
    );
  }
}

// ── Feature row ───────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.meta,
    required this.enabled,
    required this.color,
    required this.onToggle,
  });

  final _FeatureMeta meta;
  final bool enabled;
  final Color color;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => onToggle(!enabled),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.04)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: enabled
                    ? color.withValues(alpha: 0.12)
                    : scheme.outlineVariant.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                meta.icon,
                size: 16,
                color: enabled ? color : scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: enabled
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.6),
                      fontWeight:
                          enabled ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13.5,
                    ),
                  ),
                  Text(
                    meta.desc,
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onToggle,
              activeThumbColor: color,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return Colors.white;
                return null;
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick toggle button ───────────────────────────────────────────────────────

class _QuickToggleBtn extends StatelessWidget {
  const _QuickToggleBtn({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: active ? color : color.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: active
                ? Colors.white
                : color.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

// ── Actions bar ───────────────────────────────────────────────────────────────

class _ActionsBar extends StatelessWidget {
  const _ActionsBar({
    required this.isEdit,
    required this.submitting,
    required this.accentColor,
    required this.onCancel,
    required this.onDraft,
    required this.onSave,
  });

  final bool isEdit;
  final bool submitting;
  final Color accentColor;
  final VoidCallback onCancel;
  final VoidCallback? onDraft;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? scheme.surface : Colors.white,
        border: Border(
          top: BorderSide(
            color: scheme.outline.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (onDraft != null) ...[
            OutlinedButton.icon(
              onPressed: submitting ? null : onDraft,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save Draft'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: scheme.outline.withValues(alpha: 0.4)),
                foregroundColor: scheme.onSurface.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const Spacer(),
          TextButton(
            onPressed: submitting ? null : onCancel,
            style: TextButton.styleFrom(
              foregroundColor: scheme.onSurface.withValues(alpha: 0.6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
            ),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: submitting ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w600),
              elevation: 0,
            ),
            icon: submitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : Icon(isEdit ? Icons.check_rounded : Icons.add_rounded,
                    size: 17),
            label: Text(isEdit ? AppStrings.saveChanges : AppStrings.createPlan),
          ),
        ],
      ),
    );
  }
}
