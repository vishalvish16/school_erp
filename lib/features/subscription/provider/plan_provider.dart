// =============================================================================
// FILE: lib/features/subscription/provider/plan_provider.dart
// PURPOSE: ChangeNotifier for managing Platform Plan state and UI updates
// =============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/plan_model.dart';
import '../data/services/plan_service.dart';

/// Provider definition for easy access across the app
final planProvider = ChangeNotifierProvider<PlanNotifier>((ref) {
  final service = ref.read(planServiceProvider);
  return PlanNotifier(service);
});

class PlanNotifier extends ChangeNotifier {
  final PlanService _service;

  PlanNotifier(this._service);

  // --- State ---
  List<PlanModel> _plans = [];
  bool _isLoading = false;
  String? _error;

  // --- Getters ---
  List<PlanModel> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Methods ---

  /// Fetch all plans from the backend
  Future<void> fetchPlans() async {
    _setLoading(true);
    _error = null;

    try {
      _plans = await _service.getPlans();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new plan and refresh the list
  Future<bool> createPlan(Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _service.createPlan(data);
      await fetchPlans();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Update an existing plan and refresh the list
  Future<bool> updatePlan(int id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      await _service.updatePlan(id, data);
      await fetchPlans();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Delete a plan and refresh the list
  Future<bool> deletePlan(int id) async {
    _setLoading(true);
    try {
      await _service.deletePlan(id);
      await fetchPlans();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Toggle the active status of a plan and refresh the list
  Future<bool> toggleStatus(int id) async {
    _setLoading(true);
    try {
      await _service.togglePlanStatus(id);
      await fetchPlans();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // --- Helpers ---

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Clear the current error state
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
