import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/teacher_service.dart';
import '../../../../design_system/design_system.dart';
import '../providers/teacher_attendance_provider.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_spacing.dart';

const Color _accent = AppColors.success500;

class TeacherDiaryFormScreen extends ConsumerStatefulWidget {
  const TeacherDiaryFormScreen({super.key, this.diaryId});

  final String? diaryId;
  bool get isEditing => diaryId != null;

  @override
  ConsumerState<TeacherDiaryFormScreen> createState() =>
      _TeacherDiaryFormScreenState();
}

class _TeacherDiaryFormScreenState
    extends ConsumerState<TeacherDiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _topicCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pageFromCtrl = TextEditingController();
  final _pageToCtrl = TextEditingController();
  final _homeworkCtrl = TextEditingController();
  final _remarksCtrl = TextEditingController();

  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubject;
  DateTime _date = DateTime.now();
  int? _periodNo;
  bool _isSaving = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final service = ref.read(teacherServiceProvider);
      final entries = await service.getDiaryEntries(limit: 100);
      final dataWrapper = entries['data'];
      if (dataWrapper is Map<String, dynamic>) {
        final rawList = dataWrapper['data'];
        if (rawList is List) {
          final match = rawList.firstWhere(
            (e) => e is Map && e['id'] == widget.diaryId,
            orElse: () => null,
          );
          if (match is Map<String, dynamic> && mounted) {
            setState(() {
              _topicCtrl.text = match['topic_covered'] ?? '';
              _descCtrl.text = match['description'] ?? '';
              _pageFromCtrl.text = match['page_from'] ?? '';
              _pageToCtrl.text = match['page_to'] ?? '';
              _homeworkCtrl.text = match['homework_given'] ?? '';
              _remarksCtrl.text = match['remarks'] ?? '';
              _periodNo = (match['period_no'] as num?)?.toInt();
              final d = DateTime.tryParse(match['date'] ?? '');
              if (d != null) _date = d;
              _loaded = true;
            });
            return;
          }
        }
      }
      if (mounted) setState(() => _loaded = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loaded = true);
      AppSnackbar.error(context, 'Failed to load: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSectionId == null || _selectedSubject == null) {
      AppSnackbar.warning(context, 'Please select class, section and subject');
      return;
    }

    setState(() => _isSaving = true);

    final dateStr =
        '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';
    final body = <String, dynamic>{
      'class_id': _selectedClassId,
      'section_id': _selectedSectionId,
      'subject': _selectedSubject,
      'date': dateStr,
      if (_periodNo != null) 'period_no': _periodNo,
      'topic_covered': _topicCtrl.text.trim(),
      if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      if (_pageFromCtrl.text.trim().isNotEmpty)
        'page_from': _pageFromCtrl.text.trim(),
      if (_pageToCtrl.text.trim().isNotEmpty)
        'page_to': _pageToCtrl.text.trim(),
      if (_homeworkCtrl.text.trim().isNotEmpty)
        'homework_given': _homeworkCtrl.text.trim(),
      if (_remarksCtrl.text.trim().isNotEmpty)
        'remarks': _remarksCtrl.text.trim(),
    };

    try {
      final service = ref.read(teacherServiceProvider);
      if (widget.isEditing) {
        await service.updateDiaryEntry(widget.diaryId!, body);
      } else {
        await service.createDiaryEntry(body);
      }
      if (!mounted) return;
      AppSnackbar.success(context, widget.isEditing ? 'Entry updated' : 'Entry created');
      context.go('/teacher/diary');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    _descCtrl.dispose();
    _pageFromCtrl.dispose();
    _pageToCtrl.dispose();
    _homeworkCtrl.dispose();
    _remarksCtrl.dispose();
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
                  onPressed: () => context.go('/teacher/diary'),
                  icon: const Icon(Icons.arrow_back),
                ),
                AppSpacing.hGapSm,
                Text(
                  widget.isEditing ? 'Edit Diary Entry' : 'New Diary Entry',
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
                                final sec = sections.firstWhere(
                                    (s) => s.sectionId == val);
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
                                        s.sectionId ==
                                        _selectedSectionId)
                                    .expand((s) => s.subjects)
                                    .toSet()
                                    .map((subj) => DropdownMenuItem(
                                          value: subj,
                                          child: Text(subj),
                                        ))
                                    .toList(),
                                onChanged: (val) => setState(
                                    () => _selectedSubject = val),
                                validator: (v) =>
                                    v == null ? 'Required' : null,
                              ),
                          ],
                        ),
                      ),
                      AppSpacing.vGapLg,

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Date *',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(_formatDate(_date)),
                              ),
                            ),
                          ),
                          AppSpacing.hGapLg,
                          SizedBox(
                            width: 120,
                            child: DropdownButtonFormField<int>(
                              value: _periodNo,
                              decoration: const InputDecoration(
                                labelText: 'Period',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('—')),
                                ...List.generate(
                                  8,
                                  (i) => DropdownMenuItem(
                                    value: i + 1,
                                    child: Text('${i + 1}'),
                                  ),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _periodNo = val),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapLg,

                      TextFormField(
                        controller: _topicCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Topic Covered *',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 500,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Topic is required'
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
                        maxLines: 3,
                      ),
                      AppSpacing.vGapLg,

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _pageFromCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Page From',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          AppSpacing.hGapLg,
                          Expanded(
                            child: TextFormField(
                              controller: _pageToCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Page To',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.vGapLg,

                      TextFormField(
                        controller: _homeworkCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Homework Given',
                          border: OutlineInputBorder(),
                        ),
                        maxLength: 500,
                      ),
                      AppSpacing.vGapLg,

                      TextFormField(
                        controller: _remarksCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Remarks',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                      ),
                      AppSpacing.vGapXl2,

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () =>
                                context.go('/teacher/diary'),
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
