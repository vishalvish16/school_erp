import 'package:dio/dio.dart';
import '../../domain/models/school_model.dart';
import '../../domain/models/pagination_model.dart';

abstract class ISchoolsRepository {
  Future<PaginationModel<SchoolModel>> getSchools({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  });
  Future<SchoolModel> createSchool(Map<String, dynamic> data);
  Future<SchoolModel> updateSchool(String id, Map<String, dynamic> data);
  Future<void> suspendSchool(String id);
  Future<SchoolModel> getSchoolById(String id);

  // Subscription management
  Future<dynamic> assignPlan(String id, Map<String, dynamic> data);
  Future<dynamic> toggleSubscriptionStatus(String id);
  Future<dynamic> extendSubscription(String id, int months);

  // Prepare for future AI analytics
  Future<Map<String, dynamic>> getSchoolAIAnalytics(String id);
}

class SchoolsRepository implements ISchoolsRepository {
  final Dio _dio;

  SchoolsRepository(this._dio);

  @override
  Future<PaginationModel<SchoolModel>> getSchools({
    int page = 1,
    int limit = 10,
    String? search,
    String? status,
  }) async {
    final Map<String, dynamic> query = {'page': page, 'limit': limit};
    if (search != null && search.isNotEmpty) query['search'] = search;
    if (status != null && status.isNotEmpty && status != 'ALL')
      query['status'] = status;

    final response = await _dio.get(
      '/api/platform/schools',
      queryParameters: query,
    );

    Map<String, dynamic> payload = {};

    if (response.data is Map<String, dynamic>) {
      final resData = response.data['data'] ?? response.data;
      if (resData is Map<String, dynamic>) {
        payload = Map<String, dynamic>.from(resData);
        if (payload.containsKey('schools')) {
          payload['data'] = payload['schools'];
        }
      }
    } else if (response.data is List) {
      payload = {'data': response.data};
    }

    print('DEBUG API PAYLOAD: $payload');

    return PaginationModel<SchoolModel>.fromJson(
      payload,
      (json) => SchoolModel.fromJson(json),
    );
  }

  @override
  Future<SchoolModel> createSchool(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/platform/schools', data: data);
    return SchoolModel.fromJson(response.data['data']);
  }

  @override
  Future<SchoolModel> updateSchool(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/platform/schools/$id', data: data);
    return SchoolModel.fromJson(response.data['data']);
  }

  @override
  Future<void> suspendSchool(String id) async {
    await _dio.delete('/api/platform/schools/$id');
  }

  @override
  Future<SchoolModel> getSchoolById(String id) async {
    final response = await _dio.get('/api/platform/schools/$id');
    return SchoolModel.fromJson(response.data['data']);
  }

  @override
  Future<dynamic> assignPlan(String id, Map<String, dynamic> data) async {
    final response = await _dio.post(
      '/api/platform/schools/$id/assign-plan',
      data: data,
    );
    return response.data['data'];
  }

  @override
  Future<dynamic> toggleSubscriptionStatus(String id) async {
    final response = await _dio.patch(
      '/api/platform/subscriptions/$id/toggle-status',
    );
    return response.data['data'];
  }

  @override
  Future<dynamic> extendSubscription(String id, int months) async {
    final response = await _dio.patch(
      '/api/platform/subscriptions/$id/extend',
      data: {'extend_months': months},
    );
    return response.data['data'];
  }

  @override
  Future<Map<String, dynamic>> getSchoolAIAnalytics(String id) async {
    // Scaffold API integration point for AI dashboard analytics data logic
    final response = await _dio.get('/api/platform/schools/$id/analytics');
    return response.data['data'];
  }
}
