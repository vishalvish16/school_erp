// =============================================================================
// FILE: lib/features/school_admin/presentation/providers/school_admin_fees_provider.dart
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/school_admin_service.dart';
import '../../../../models/school_admin/fee_structure_model.dart';
import '../../../../models/school_admin/fee_payment_model.dart';

class FeesState {
  final List<FeeStructureModel> structures;
  final List<FeePaymentModel> payments;
  final Map<String, dynamic> summary;
  final bool isLoading;
  final bool isLoadingPayments;
  final String? errorMessage;
  final int currentPage;
  final int totalPages;

  const FeesState({
    this.structures = const [],
    this.payments = const [],
    this.summary = const {},
    this.isLoading = false,
    this.isLoadingPayments = false,
    this.errorMessage,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  FeesState copyWith({
    List<FeeStructureModel>? structures,
    List<FeePaymentModel>? payments,
    Map<String, dynamic>? summary,
    bool? isLoading,
    bool? isLoadingPayments,
    String? errorMessage,
    int? currentPage,
    int? totalPages,
    bool clearError = false,
  }) =>
      FeesState(
        structures: structures ?? this.structures,
        payments: payments ?? this.payments,
        summary: summary ?? this.summary,
        isLoading: isLoading ?? this.isLoading,
        isLoadingPayments: isLoadingPayments ?? this.isLoadingPayments,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages ?? this.totalPages,
      );
}

class FeesNotifier extends StateNotifier<FeesState> {
  final SchoolAdminService _service;

  FeesNotifier(this._service) : super(const FeesState());

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
        studentId: studentId,
        month: month,
        academicYear: academicYear,
      );
      final dataWrapper = response['data'];
      List<dynamic> rawList = [];
      Map<String, dynamic> pagination = {};
      if (dataWrapper is Map) {
        rawList = (dataWrapper['data'] as List?) ?? [];
        pagination = (dataWrapper['pagination'] as Map<String, dynamic>?) ?? {};
      } else if (dataWrapper is List) {
        rawList = dataWrapper;
      }
      final payments = rawList
          .map((e) => FeePaymentModel.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(
        payments: payments,
        isLoadingPayments: false,
        currentPage: (pagination['page'] as num?)?.toInt() ?? page,
        totalPages: (pagination['total_pages'] as num?)?.toInt() ?? 1,
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

  Future<bool> createStructure(Map<String, dynamic> data) async {
    try {
      await _service.createFeeStructure(data);
      await loadStructures();
      return true;
    } catch (e) {
      state = state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> updateStructure(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateFeeStructure(id, data);
      await loadStructures();
      return true;
    } catch (e) {
      state = state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> deleteStructure(String id) async {
    try {
      await _service.deleteFeeStructure(id);
      await loadStructures();
      return true;
    } catch (e) {
      state = state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> collectFee(Map<String, dynamic> data) async {
    try {
      await _service.collectFee(data);
      await loadPayments();
      await loadSummary();
      return true;
    } catch (e) {
      state = state.copyWith(
          errorMessage: e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }
}

final schoolAdminFeesProvider =
    StateNotifierProvider<FeesNotifier, FeesState>((ref) {
  return FeesNotifier(ref.read(schoolAdminServiceProvider));
});
