import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/school_model.dart';
import '../../data/repositories/schools_repository.dart';
import '../../data/providers/schools_providers.dart';

final schoolDetailViewModelProvider =
    StateNotifierProvider.family<
      SchoolDetailViewModel,
      AsyncValue<SchoolModel>,
      String
    >((ref, id) {
      final repository = ref.watch(schoolsRepositoryProvider);
      return SchoolDetailViewModel(repository, id);
    });

class SchoolDetailViewModel extends StateNotifier<AsyncValue<SchoolModel>> {
  final ISchoolsRepository _repository;
  final String _id;

  SchoolDetailViewModel(this._repository, this._id)
    : super(const AsyncValue.loading()) {
    fetchSchool();
  }

  Future<void> fetchSchool() async {
    state = const AsyncValue.loading();
    try {
      final school = await _repository.getSchoolById(_id);
      state = AsyncValue.data(school);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> assignPlan({
    required String planId,
    required String billingCycle,
    int? durationMonths,
  }) async {
    try {
      await _repository.assignPlan(_id, {
        'plan_id': planId,
        'billing_cycle': billingCycle,
        'duration_months': ?durationMonths,
      });
      await fetchSchool(); // Refresh data
    } catch (e) {
      // Error handling by the UI
      rethrow;
    }
  }

  Future<void> toggleSubscriptionStatus(String subscriptionId) async {
    try {
      await _repository.toggleSubscriptionStatus(subscriptionId);
      await fetchSchool();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> extendSubscription(String subscriptionId, int months) async {
    try {
      await _repository.extendSubscription(subscriptionId, months);
      await fetchSchool();
    } catch (e) {
      rethrow;
    }
  }
}
