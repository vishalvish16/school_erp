// =============================================================================
// FILE: lib/features/auth/school_setup_search_widget.dart
// PURPOSE: Search school by name for staff — debounced API call
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/network/dio_client.dart';
import '../../models/school_identity.dart';
import '../../design_system/design_system.dart';

/// Layout mode for search results.
enum SchoolSearchLayout {
  /// Results appear inline below search input (original behavior).
  inline,
  /// Results appear below a middle widget (e.g. login box).
  resultsBelowMiddle,
  /// Results appear in a popup/bottom sheet — no scrollbar, compact main screen.
  popup,
}

class SchoolSetupSearchWidget extends ConsumerStatefulWidget {
  const SchoolSetupSearchWidget({
    super.key,
    required this.onSchoolSelected,
    this.layout = SchoolSearchLayout.inline,
    this.middleContent,
  });

  final ValueChanged<SchoolIdentity> onSchoolSelected;
  final SchoolSearchLayout layout;
  /// Content to render between search input and results when layout is resultsBelowMiddle.
  final Widget? middleContent;

  @override
  ConsumerState<SchoolSetupSearchWidget> createState() => _SchoolSetupSearchWidgetState();
}

class _SchoolSetupSearchWidgetState extends ConsumerState<SchoolSetupSearchWidget> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final q = _controller.text.trim();
    if (q.length < 2) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(
        '/api/public/schools/search',
        queryParameters: {'q': q, 'limit': 10},
      );
      if (!mounted) return;
      final data = res.data;
      List<dynamic> list = [];
      if (data is Map && data['data'] != null) {
        list = data['data'] is List ? data['data'] as List : [data['data']];
      } else if (data is List) {
        list = data;
      }
      setState(() {
        _results = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (mounted) {
        String msg = 'Could not connect. ';
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          msg += 'Ensure backend is running. Physical device? Run with: '
              'flutter run --dart-define=API_HOST=YOUR_PC_IP';
        } else {
          msg += 'Check your connection and try again.';
        }
        setState(() {
          _error = msg;
          _results = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not connect. Physical device? Use: '
              'flutter run --dart-define=API_HOST=YOUR_PC_IP';
          _results = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final useResultsBelowMiddle =
        widget.layout == SchoolSearchLayout.resultsBelowMiddle &&
            widget.middleContent != null;
    final usePopup = widget.layout == SchoolSearchLayout.popup;

    if (usePopup && widget.middleContent != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchInputSection(openPopupOnTap: true),
          AppSpacing.vGapXl,
          widget.middleContent!,
        ],
      );
    }

    if (useResultsBelowMiddle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSearchInputSection(),
          AppSpacing.vGapXl,
          widget.middleContent!,
          _buildResultsSection(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchInputSection(openPopupOnTap: false),
        _buildResultsSection(),
      ],
    );
  }

  void _openSearchPopup() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SchoolSearchPopup(
        onSchoolSelected: (school) {
          Navigator.pop(ctx);
          widget.onSchoolSelected(school);
        },
        dio: ref.read(dioProvider),
      ),
    );
  }

  Widget _buildSearchInputSection({bool openPopupOnTap = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.searchYourSchool,
          style: AuthTextStyles.tagline.copyWith(
            color: AuthColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.vGapMd,
        GestureDetector(
          onTap: openPopupOnTap ? _openSearchPopup : null,
          child: AbsorbPointer(
            absorbing: openPopupOnTap,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              readOnly: openPopupOnTap,
              decoration: InputDecoration(
                hintText: AppStrings.typeSchoolNameOrCity,
                hintStyle: AuthTextStyles.inputHint,
                prefixIcon: const Icon(Icons.search, color: AuthColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AuthSizes.formFieldRadius),
                  borderSide: const BorderSide(color: AuthColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AuthSizes.formFieldRadius),
                  borderSide: const BorderSide(color: AuthColors.border),
                ),
              ),
              style: AuthTextStyles.inputText,
              onChanged: (_) {},
            ),
          ),
        ),
        if (_error != null) ...[
          AppSpacing.vGapMd,
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: AppColors.error500.withValues(alpha: 0.1),
              borderRadius: AppRadius.brMd,
              border: Border.all(color: AppColors.error500.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: AppColors.error700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: AuthTextStyles.tagline.copyWith(
                      color: AppColors.error700,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final q = _controller.text.trim();
                    if (q.length >= 2) _search(q);
                  },
                  child: const Text(AppStrings.retry),
                ),
              ],
            ),
          ),
        ],
        if (_isLoading) ...[
          AppSpacing.vGapLg,
          AppLoaderScreen(),
        ],
      ],
    );
  }

  Widget _buildResultsSection() {
    if (_results.isEmpty &&
        !(_controller.text.trim().length >= 2 &&
            !_isLoading &&
            _error == null)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_results.isNotEmpty) ...[
            ..._results.map((r) => _buildResultItem(r)),
          ],
          if (_controller.text.trim().length >= 2 &&
              !_isLoading &&
              _results.isEmpty &&
              _error == null) ...[
            Text(
              AppStrings.noResults,
              style: AuthTextStyles.tagline.copyWith(
                fontSize: 13,
                color: AuthColors.textSecondary,
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              AppStrings.askSchoolAdmin,
              style: AuthTextStyles.inputHint.copyWith(
                fontSize: 12,
                color: AuthColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> r) {
    final school = SchoolIdentity(
      id: r['id']?.toString() ?? '',
      name: r['name']?.toString() ?? '',
      code: r['code']?.toString() ?? '',
      logoUrl: r['logo_url']?.toString(),
      board: r['board']?.toString() ?? '',
      type: r['type']?.toString() ?? 'school',
      studentCount: (r['student_count'] ?? r['studentCount']) is int
          ? (r['student_count'] ?? r['studentCount']) as int
          : null,
      active: r['is_active'] == true || r['active'] == true,
    );
    final city = r['city']?.toString() ?? '';
    final state = r['state']?.toString() ?? '';
    final board = r['board']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
        child: InkWell(
          onTap: () => widget.onSchoolSelected(school),
          borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AuthColors.border),
              borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
            ),
            padding: AppSpacing.paddingLg,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AuthColors.primary.withValues(alpha: 0.1),
                  backgroundImage: school.logoUrl != null ? NetworkImage(school.logoUrl!) : null,
                  child: school.logoUrl == null
                      ? Text(
                          school.name.isNotEmpty ? school.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AuthColors.primary,
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
                        school.name,
                        style: AuthTextStyles.featurePoint,
                      ),
                      if (city.isNotEmpty || state.isNotEmpty)
                        Text(
                          [city, state].where((e) => e.isNotEmpty).join(', '),
                          style: AuthTextStyles.tagline.copyWith(fontSize: 12),
                        ),
                      if (board.isNotEmpty)
                        Text(board, style: AuthTextStyles.inputHint.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                if (school.active)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AuthColors.success.withValues(alpha: 0.15),
                      borderRadius: AppRadius.brLg,
                    ),
                    child: Text(
                      AppStrings.active,
                      style: AuthTextStyles.tagline.copyWith(
                        color: AuthColors.success,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Popup/bottom sheet for school search — search box + results list.
class _SchoolSearchPopup extends StatefulWidget {
  const _SchoolSearchPopup({
    required this.onSchoolSelected,
    required this.dio,
  });

  final ValueChanged<SchoolIdentity> onSchoolSelected;
  final Dio dio;

  @override
  State<_SchoolSearchPopup> createState() => _SchoolSearchPopupState();
}

class _SchoolSearchPopupState extends State<_SchoolSearchPopup> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    final q = _controller.text.trim();
    if (q.length < 2) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await widget.dio.get(
        '/api/public/schools/search',
        queryParameters: {'q': q, 'limit': 10},
      );
      if (!mounted) return;
      final data = res.data;
      List<dynamic> list = [];
      if (data is Map && data['data'] != null) {
        list = data['data'] is List ? data['data'] as List : [data['data']];
      } else if (data is List) {
        list = data;
      }
      setState(() {
        _results = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _isLoading = false;
      });
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.connectionError
              ? 'Could not connect. Check your network.'
              : AppStrings.searchFailed;
          _results = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = AppStrings.searchFailed;
          _results = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSpacing.vGapMd,
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AuthColors.border,
                borderRadius: AppRadius.brXs,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              AppStrings.searchYourSchool,
              style: AuthTextStyles.tagline.copyWith(
                color: AuthColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: AppStrings.typeSchoolNameOrCity,
                hintStyle: AuthTextStyles.inputHint,
                prefixIcon: const Icon(Icons.search, color: AuthColors.textSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AuthSizes.formFieldRadius),
                  borderSide: const BorderSide(color: AuthColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AuthSizes.formFieldRadius),
                  borderSide: const BorderSide(color: AuthColors.border),
                ),
              ),
              style: AuthTextStyles.inputText,
              onChanged: (_) {},
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: AppSpacing.paddingMd,
                decoration: BoxDecoration(
                  color: AppColors.error500.withValues(alpha: 0.1),
                  borderRadius: AppRadius.brMd,
                  border: Border.all(color: AppColors.error500.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off_rounded, color: AppColors.error700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AuthTextStyles.tagline.copyWith(
                          color: AppColors.error700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final q = _controller.text.trim();
                        if (q.length >= 2) _search(q);
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                ),
              ),
            ),
          if (_isLoading)
            Padding(
              padding: AppSpacing.paddingXl,
              child: AppLoaderScreen(),
            )
          else
            Flexible(
              child: _results.isEmpty
                  ? _controller.text.trim().length >= 2 && _error == null
                      ? Padding(
                          padding: AppSpacing.paddingXl,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                AppStrings.noResults,
                                style: AuthTextStyles.tagline.copyWith(
                                  fontSize: 13,
                                  color: AuthColors.textSecondary,
                                ),
                              ),
                              AppSpacing.vGapXs,
                              Text(
                                AppStrings.askSchoolAdmin,
                                style: AuthTextStyles.inputHint.copyWith(
                                  fontSize: 12,
                                  color: AuthColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink()
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomPadding),
                      itemCount: _results.length,
                      itemBuilder: (context, i) => _buildResultItem(_results[i]),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildResultItem(Map<String, dynamic> r) {
    final school = SchoolIdentity(
      id: r['id']?.toString() ?? '',
      name: r['name']?.toString() ?? '',
      code: r['code']?.toString() ?? '',
      logoUrl: r['logo_url']?.toString(),
      board: r['board']?.toString() ?? '',
      type: r['type']?.toString() ?? 'school',
      studentCount: (r['student_count'] ?? r['studentCount']) is int
          ? (r['student_count'] ?? r['studentCount']) as int
          : null,
      active: r['is_active'] == true || r['active'] == true,
    );
    final city = r['city']?.toString() ?? '';
    final state = r['state']?.toString() ?? '';
    final board = r['board']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
        child: InkWell(
          onTap: () => widget.onSchoolSelected(school),
          borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AuthColors.border),
              borderRadius: BorderRadius.circular(AuthSizes.glassRadius),
            ),
            padding: AppSpacing.paddingLg,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AuthColors.primary.withValues(alpha: 0.1),
                  backgroundImage: school.logoUrl != null ? NetworkImage(school.logoUrl!) : null,
                  child: school.logoUrl == null
                      ? Text(
                          school.name.isNotEmpty ? school.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AuthColors.primary,
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
                        school.name,
                        style: AuthTextStyles.featurePoint,
                      ),
                      if (city.isNotEmpty || state.isNotEmpty)
                        Text(
                          [city, state].where((e) => e.isNotEmpty).join(', '),
                          style: AuthTextStyles.tagline.copyWith(fontSize: 12),
                        ),
                      if (board.isNotEmpty)
                        Text(board, style: AuthTextStyles.inputHint.copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                if (school.active)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AuthColors.success.withValues(alpha: 0.15),
                      borderRadius: AppRadius.brLg,
                    ),
                    child: Text(
                      AppStrings.active,
                      style: AuthTextStyles.tagline.copyWith(
                        color: AuthColors.success,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
