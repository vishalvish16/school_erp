import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/teacher_service.dart';
import '../../../../design_system/design_system.dart';
import '../providers/teacher_attendance_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

class TeacherHomeworkFormScreen extends ConsumerStatefulWidget {
  const TeacherHomeworkFormScreen({super.key, this.homeworkId});

  final String? homeworkId;
  bool get isEditing => homeworkId != null;

  @override
  ConsumerState<TeacherHomeworkFormScreen> createState() =>
      _TeacherHomeworkFormScreenState();
}

class _TeacherHomeworkFormScreenState
    extends ConsumerState<TeacherHomeworkFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubject;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 3));
  bool _isSaving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    try {
      final hw = await ref
          .read(teacherServiceProvider)
          .getHomeworkDetail(widget.homeworkId!);
      if (!mounted) return;
      setState(() {
        _titleCtrl.text = hw.title;
        _descCtrl.text = hw.description ?? '';
        _dueDate = DateTime.tryParse(hw.dueDate) ?? _dueDate;
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, 'Failed to load: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSectionId == null || _selectedSubject == null) {
      AppSnackbar.warning(context, 'Please select class, section and subject');
      return;
    }

    setState(() => _isSaving = true);

    final dateStr =
        '${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}';
    final body = <String, dynamic>{
      'class_id': _selectedClassId,
      'section_id': _selectedSectionId,
      'subject': _selectedSubject,
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
      'due_date': dateStr,
      'attachment_urls': <String>[],
    };

    try {
      final service = ref.read(teacherServiceProvider);
      if (widget.isEditing) {
        await service.updateHomework(widget.homeworkId!, body);
      } else {
        await service.createHomework(body);
      }
      if (!mounted) return;
      AppSnackbar.success(context, widget.isEditing
          ? 'Homework updated'
          : 'Homework created');
      context.go('/teacher/homework');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sectionsAsync = ref.watch(teacherSectionsProvider);
    final isWide = MediaQuery.of(context).size.width >= 768;
    final padding = isWide ? 24.0 : 16.0;

    if (widget.isEditing && !_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/teacher/homework'),
                  icon: const Icon(Icons.arrow_back),
                ),
                AppSpacing.hGapSm,
                Text(
                  widget.isEditing ? 'Edit Homework' : 'New Homework',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            AppSpacing.vGapXl,

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section picker
                      sectionsAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text('Error: $e'),
                        data: (sections) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String>(
                              value: _selectedSectionId,
                              decoration: const InputDecoration(
                                labelText: 'Class - Section *',
                                border: OutlineInputBorder(),
                              ),
                              items: sections
                                  .map((s) => DropdownMenuItem(
                                        value: s.sectionId,
                                        child: Text(s.displayName),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val == null) return;
                                final sec = sections
                                    .firstWhere((s) => s.sectionId == val);
                                setState(() {
                                  _selectedSectionId = val;
                                  _selectedClassId = sec.classId;
                                  _selectedSubject = null;
                                });
                              },
                              validator: (v) =>
                                  v == null ? 'Required' : null,
                            ),
                            AppSpacing.vGapLg,
                            if (_selectedSectionId != null)
                              DropdownButtonFormField<String>(
                                value: _selectedSubject,
                                decoration: const InputDecoration(
                                  labelText: 'Subject *',
                                  border: OutlineInputBorder(),
                                ),
                                items: sections
                                    .where((s) =>
                                        s.sectionId == _selectedSectionId)
                                    .expand((s) => s.subjects)
                                    .toSet()
                                    .map((subj) => DropdownMenuItem(
                                          value: subj,
                                          child: Text(subj),
                                        ))
                                    .toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedSubject = val),
                                validator: (v) =>
                                    v == null ? 'Required' : null,
                              ),
                          ],
                        ),
                      ),
                      AppSpacing.vGapLg,

                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Title *',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 255,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                      AppSpacing.vGapLg,

                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                      ),
                      AppSpacing.vGapLg,

                      InkWell(
                        onTap: _pickDueDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(_formatDate(_dueDate)),
                        ),
                      ),
                      AppSpacing.vGapXl2,

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                context.go('/teacher/homework'),
                            child: const Text('Cancel'),
                          ),
                          AppSpacing.hGapMd,
                          FilledButton(
                            onPressed: _isSaving ? null : _save,
                            style: FilledButton.styleFrom(
                                backgroundColor: _accent),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : Text(widget.isEditing
                                    ? 'Update'
                                    : 'Create'),
                          ),
                        ],
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

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}
