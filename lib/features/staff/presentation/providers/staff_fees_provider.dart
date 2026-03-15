// =============================================================================
// FILE: lib/features/staff/presentation/providers/staff_fees_provider.dart
// PURPOSE: Fee payments, structures, and summary provider for Staff portal.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/staff_service.dart';
import '../../../../models/staff/staff_payment_model.dart';
import '../../../../models/staff/staff_fee_structure_model.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class StaffFeesState {
  final List<StaffFeeStructureModel> structures;
  final List<StaffPaymentModel> payments;
  final Map<String, dynamic> summary;
  final bool isLoading;
  final bool isLoadingPayments;
  final bool isCollecting;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;
  final int total;
  final int pageSize;
  final String? filterStudentId;
  final String? filterMonth;
  final String? filterAcademicYear;

  const StaffFeesState({
    this.structures = const [],
    this.payments = const [],
    this.summary = const {},
    this.isLoading = false,
    this.isLoadingPayments = false,
    this.isCollecting = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.total = 0,
    this.pageSize = 15,
    this.filterStudentId,
    this.filterMonth,
    this.filterAcademicYear,
  });

  StaffFeesState copyWith({
    List<StaffFeeStructureModel>? structures,
    List<StaffPaymentModel>? payments,
    Map<String, dynamic>? summary,
    bool? isLoading,
    bool? isLoadingPayments,
    bool? isCollecting,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    int? total,
    int? pageSize,
    String? filterStudentId,
    String? filterMonth,
    String? filterAcademicYear,
    bool clearError = false,
    bool clearFilterStudentId = false,
    bool clearFilterMonth = false,
    bool clearFilterAcademicYear = false,
  }) =>
      StaffFeesState(
        structures: structures ?? this.structures,
        payments: payments ?? this.payments,
        summary: summary ?? this.summary,
        isLoading: isLoading ?? this.isLoading,
        isLoadingPayments: isLoadingPayments ?? this.isLoadingPayments,
        isCollecting: isCollecting ?? this.isCollecting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        pageSize: pageSize ?? this.pageSize,
        filterStudentId: clearFilterStudentId
            ? null
            : (filterStudentId ?? this.filterStudentId),
        filterMonth:
            clearFilterMonth ? null : (filterMonth ?? this.filterMonth),
        filterAcademicYear: clearFilterAcademicYear
            ? null
            : (filterAcademicYear ?? this.filterAcademicYear),
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class StaffFeesNotifier extends StateNotifier<StaffFeesState> {
  final StaffService _service;

  StaffFeesNotifier(this._service) : super(const StaffFeesState());

  Future<void> loadStructures({
    String? academicYear,
    String? classId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final structures = await _service.getFeeStructures(
        academicYear: academicYear,
        classId: classId,
      );
      state = state.copyWith(structures: structures, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadPayments({
    int page = 1,
    String? studentId,
    String? month,
    String? academicYear,
  }) async {
    state = state.copyWith(isLoadingPayments: true, clearError: true);
    try {
      final response = await _service.getFeePayments(
        page: page,
        studentId: studentId ?? state.filterStudentId,
        month: month ?? state.filterMonth,
        academicYear: academicYear ?? state.filterAcademicYear,
      );
      final dataWrapper = response['data'];
      List<dynamic> rawList = [];
      Map<String, dynamic> pagination = {};
      if (dataWrapper is Map) {
        rawList = (dataWrapper['data'] as List?) ?? [];
        pagination =
            (dataWrapper['pagination'] as Map<String, dynamic>?) ?? {};
      } else if (dataWrapper is List) {
        rawList = dataWrapper;
      }
      final payments = rawList
          .map((e) =>
              StaffPaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        payments: payments,
        isLoadingPayments: false,
        currentPage: (pagination['page'] as num?)?.toInt() ?? page,
        totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
        total: (pagination['total'] as num?)?.toInt() ?? payments.length,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingPayments: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<void> loadSummary({String? month}) async {
    try {
      final summary = await _service.getFeeSummary(month: month);
      state = state.copyWith(summary: summary);
    } catch (_) {}
  }

  void setFilters({
    String? studentId,
    String? month,
    String? academicYear,
    bool clearStudentId = false,
    bool clearMonth = false,
    bool clearAcademicYear = false,
  }) {
    state = state.copyWith(
      filterStudentId: studentId,
      filterMonth: month,
      filterAcademicYear: academicYear,
      clearFilterStudentId: clearStudentId,
      clearFilterMonth: clearMonth,
      clearFilterAcademicYear: clearAcademicYear,
      currentPage: 1,
    );
    loadPayments(page: 1);
  }

  /// Returns the newly-created payment on success, or null on failure.
  Future<StaffPaymentModel?> collectFee(Map<String, dynamic> data) async {
    state = state.copyWith(isCollecting: true, clearError: true);
    try {
      final payment = await _service.collectFee(data);
      await loadPayments(page: 1);
      await loadSummary();
      state = state.copyWith(isCollecting: false);
      return payment;
    } catch (e) {
      state = state.copyWith(
        isCollecting: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  void goToPage(int page) {
    state = state.copyWith(currentPage: page);
    loadPayments(page: page);
  }

  void setPageSize(int size) {
    state = state.copyWith(pageSize: size, currentPage: 1);
    loadPayments(page: 1);
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final staffFeesProvider =
    StateNotifierProvider<StaffFeesNotifier, StaffFeesState>((ref) {
  return StaffFeesNotifier(ref.read(staffServiceProvider));
});
