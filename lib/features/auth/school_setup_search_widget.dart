// =============================================================================
// FILE: lib/features/auth/school_setup_search_widget.dart
// PURPOSE: Search school by name for staff — debounced API call
// =============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_auth_constants.dart';
import '../../core/network/dio_client.dart';
import '../../models/school_identity.dart';

class SchoolSetupSearchWidget extends ConsumerStatefulWidget {
  const SchoolSetupSearchWidget({
    super.key,
    required this.onSchoolSelected,
  });

  final ValueChanged<SchoolIdentity> onSchoolSelected;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Search your school',
          style: AuthTextStyles.tagline.copyWith(
            color: AuthColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Type school name or city...',
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
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off_rounded, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _error!,
                    style: AuthTextStyles.tagline.copyWith(
                      color: Colors.red.shade800,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final q = _controller.text.trim();
                    if (q.length >= 2) _search(q);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
        if (_isLoading) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._results.map((r) => _buildResultItem(r)),
        ],
        if (_controller.text.trim().length >= 2 && !_isLoading && _results.isEmpty && _error == null) ...[
          const SizedBox(height: 16),
          Text(
            'No results?',
            style: AuthTextStyles.tagline.copyWith(
              fontSize: 13,
              color: AuthColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ask your school admin for the setup link',
            style: AuthTextStyles.inputHint.copyWith(
              fontSize: 12,
              color: AuthColors.textMuted,
            ),
          ),
        ],
      ],
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
            padding: const EdgeInsets.all(16),
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
                const SizedBox(width: 16),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AuthColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
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
