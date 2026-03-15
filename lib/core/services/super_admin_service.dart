// =============================================================================
// FILE: lib/core/services/super_admin_service.dart
// PURPOSE: Super Admin API service — dashboard, schools, groups, plans, billing, etc.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/dio_client.dart';
import '../../models/super_admin/super_admin_models.dart';
import '../../features/schools/domain/models/pagination_model.dart';

const String _basePath = '/api/platform/super-admin';

class SuperAdminService {
  SuperAdminService(this._dio);

  final Dio _dio;

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Future<SuperAdminDashboardStatsModel> getDashboardStats() async {
    final res = await _dio.get('$_basePath/dashboard/stats');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SuperAdminDashboardStatsModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<List<int>> exportDashboardReport() async {
    final res = await _dio.get<List<int>>(
      '$_basePath/dashboard/export',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? [];
  }

  // ── Schools ──────────────────────────────────────────────────────────────
  Future<PaginationModel<SuperAdminSchoolModel>> getSchools({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? planId,
    String? country,
    String? state,
    String? city,
    String? groupId,
  }) async {
    final q = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (planId != null && planId.isNotEmpty) q['plan_id'] = planId;
    if (country != null && country.isNotEmpty) q['country'] = country;
    if (state != null && state.isNotEmpty) q['state'] = state;
    if (city != null && city.isNotEmpty) q['city'] = city;
    if (groupId != null && groupId.isNotEmpty) q['group_id'] = groupId;

    final res = await _dio.get('$_basePath/schools', queryParameters: q);
    final raw = res.data;
    final payload = raw is Map && raw['data'] is Map
        ? raw['data'] as Map<String, dynamic>
        : (raw is Map ? raw as Map<String, dynamic> : {'data': [], 'pagination': {}});
    return PaginationModel.fromJson(
      payload,
      (j) => SuperAdminSchoolModel.fromJson(j),
    );
  }

  Future<SuperAdminSchoolModel> getSchoolById(String id) async {
    final res = await _dio.get('$_basePath/schools/$id');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SuperAdminSchoolModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<SuperAdminSchoolModel> createSchool(Map<String, dynamic> body) async {
    final res = await _dio.post('$_basePath/schools', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SuperAdminSchoolModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<SuperAdminSchoolModel> updateSchool(String id, Map<String, dynamic> body) async {
    final res = await _dio.put('$_basePath/schools/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SuperAdminSchoolModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<void> updateSchoolStatus(String id, String status, {String? reason}) async {
    await _dio.put('$_basePath/schools/$id/status', data: {'status': status, 'reason': reason});
  }

  Future<void> updateSchoolSubdomain(String id, String subdomain) async {
    await _dio.put('$_basePath/schools/$id/subdomain', data: {'subdomain': subdomain});
  }

  Future<void> resetSchoolAdminPassword(String schoolId, String userId, String newPassword) async {
    await _dio.put('$_basePath/schools/$schoolId/admin/reset-password', data: {
      'user_id': userId,
      'new_password': newPassword,
    });
  }

  Future<void> deactivateSchoolAdmin(String schoolId, String userId) async {
    await _dio.put('$_basePath/schools/$schoolId/admin/$userId/deactivate');
  }

  Future<void> assignSchoolAdmin(String schoolId, Map<String, dynamic> body) async {
    await _dio.post('$_basePath/schools/$schoolId/admin/assign', data: body);
  }

  Future<bool> checkSubdomainAvailable(String value) async {
    try {
      final res = await _dio.get(
        '$_basePath/schools/check-subdomain',
        queryParameters: {'value': value},
      );
      final data = res.data is Map ? res.data['data'] ?? res.data : {};
      return data['available'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<List<int>> exportSchools({String? search, String? status, String? planId, String? country, String? state, String? city}) async {
    final q = <String, String>{};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (planId != null && planId.isNotEmpty) q['plan_id'] = planId;
    if (country != null && country.isNotEmpty) q['country'] = country;
    if (state != null && state.isNotEmpty) q['state'] = state;
    if (city != null && city.isNotEmpty) q['city'] = city;
    final res = await _dio.get<List<int>>(
      '$_basePath/schools/export',
      queryParameters: q.isEmpty ? null : q,
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? [];
  }

  // ── Groups ───────────────────────────────────────────────────────────────
  Future<List<SuperAdminSchoolGroupModel>> getGroups({
    int? page,
    int? limit,
    String? search,
    String? status,
  }) async {
    final q = <String, String>{};
    if (page != null) q['page'] = page.toString();
    if (limit != null) q['limit'] = limit.toString();
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (status != null && status.isNotEmpty) q['status'] = status;

    final res = await _dio.get('$_basePath/groups', queryParameters: q.isEmpty ? null : q);
    final raw = res.data;
    // API returns { success, message, data: { data: [...], pagination: {...} } }
    dynamic list;
    if (raw is Map) {
      final inner = raw['data'];
      if (inner is Map && inner['data'] is List) {
        list = inner['data'];
      } else if (inner is List) {
        list = inner;
      }
    }
    if (list is! List) return [];
    return list
        .map((e) => SuperAdminSchoolGroupModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<Map<String, dynamic>> getGroupById(String id) async {
    final response = await _dio.get('$_basePath/groups/$id');
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  Future<void> deleteGroup(String id) async {
    await _dio.delete('$_basePath/groups/$id');
  }

  Future<Map<String, dynamic>> assignGroupAdmin(String groupId, Map<String, dynamic> data) async {
    final response = await _dio.post('$_basePath/groups/$groupId/admin/assign', data: data);
    return response.data is Map<String, dynamic> ? response.data : {};
  }

  Future<void> resetGroupAdminPassword(String groupId, String newPassword) async {
    await _dio.put('$_basePath/groups/$groupId/admin/reset-password',
      data: {'new_password': newPassword});
  }

  Future<void> lockGroupAdmin(String groupId) async {
    await _dio.put('$_basePath/groups/$groupId/admin/lock');
  }

  Future<void> unlockGroupAdmin(String groupId) async {
    await _dio.put('$_basePath/groups/$groupId/admin/unlock');
  }

  Future<void> deactivateGroupAdmin(String groupId) async {
    await _dio.put('$_basePath/groups/$groupId/admin/deactivate');
  }

  Future<bool> checkGroupSlugAvailable(String value, {String? excludeId}) async {
    try {
      final q = <String, String>{'value': value};
      if (excludeId != null && excludeId.isNotEmpty) q['exclude_id'] = excludeId;
      final res = await _dio.get(
        '$_basePath/groups/check-slug',
        queryParameters: q,
      );
      final data = res.data is Map ? res.data['data'] ?? res.data : {};
      return data['available'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<SuperAdminSchoolGroupModel> createGroup(Map<String, dynamic> body) async {
    final res = await _dio.post('$_basePath/groups', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SuperAdminSchoolGroupModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<SuperAdminSchoolGroupModel> updateGroup(String id, Map<String, dynamic> body) async {
    final res = await _dio.put('$_basePath/groups/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SuperAdminSchoolGroupModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<void> addSchoolToGroup(String groupId, String schoolId) async {
    await _dio.post('$_basePath/groups/$groupId/add-school', data: {'school_id': schoolId});
  }

  Future<void> removeSchoolFromGroup(String groupId, String schoolId) async {
    await _dio.delete('$_basePath/groups/$groupId/remove-school/$schoolId');
  }

  // ── Plans ────────────────────────────────────────────────────────────────
  Future<List<SuperAdminPlanModel>> getPlans() async {
    final res = await _dio.get('$_basePath/plans');
    final list = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (list is! List) return [];
    return list
        .map((e) => SuperAdminPlanModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<SuperAdminPlanModel> createPlan(Map<String, dynamic> body) async {
    final res = await _dio.post('$_basePath/plans', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SuperAdminPlanModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<SuperAdminPlanModel> updatePlan(String id, Map<String, dynamic> body) async {
    final res = await _dio.put('$_basePath/plans/$id', data: body);
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return SuperAdminPlanModel.fromJson(
      data is Map<String, dynamic> ? data : {},
    );
  }

  Future<void> updatePlanStatus(String id, String status) async {
    await _dio.put('$_basePath/plans/$id/status', data: {'status': status});
  }

  Future<List<SuperAdminAuditLogModel>> getPlanChangeLog(String planId) async {
    final res = await _dio.get('$_basePath/plans/$planId/change-log');
    final list = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (list is! List) return [];
    return list
        .map((e) => SuperAdminAuditLogModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  // ── Billing ───────────────────────────────────────────────────────────────
  Future<PaginationModel<SuperAdminSchoolSubscriptionModel>> getSubscriptions({
    String? status,
    int? expiringDays,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final q = <String, String>{'page': page.toString(), 'limit': limit.toString()};
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (expiringDays != null) q['expiring_days'] = expiringDays.toString();
    if (search != null && search.isNotEmpty) q['search'] = search;

    final res = await _dio.get('$_basePath/billing/subscriptions', queryParameters: q);
    final raw = res.data;
    final payload = raw is Map && raw['data'] is Map
        ? raw['data'] as Map<String, dynamic>
        : (raw is Map ? raw as Map<String, dynamic> : {'data': [], 'pagination': {}});
    return PaginationModel.fromJson(
      payload,
      (j) => SuperAdminSchoolSubscriptionModel.fromJson(j),
    );
  }

  Future<void> renewSubscription(String schoolId, Map<String, dynamic> body) async {
    await _dio.post('$_basePath/billing/subscriptions/$schoolId/renew', data: body);
  }

  Future<void> assignPlan(String schoolId, Map<String, dynamic> body) async {
    await _dio.post('$_basePath/billing/subscriptions/$schoolId/assign-plan', data: body);
  }

  Future<void> resolveOverdue(String schoolId, Map<String, dynamic> body) async {
    await _dio.post('$_basePath/billing/resolve-overdue/$schoolId', data: body);
  }

  Future<List<int>> exportBilling() async {
    final res = await _dio.get<List<int>>(
      '$_basePath/billing/export',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? [];
  }

  // ── Features ─────────────────────────────────────────────────────────────
  Future<List<SuperAdminPlatformFeatureModel>> getPlatformFeatures() async {
    final res = await _dio.get('$_basePath/features/platform');
    final list = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (list is! List) return [];
    return list
        .map((e) => SuperAdminPlatformFeatureModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<void> togglePlatformFeature(String featureKey, bool enabled) async {
    await _dio.put('$_basePath/features/platform/$featureKey', data: {'is_enabled': enabled});
  }

  Future<Map<String, bool>> getSchoolFeatures(String schoolId) async {
    final res = await _dio.get('$_basePath/features/school/$schoolId');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (data is! Map) return {};
    return (data).map((k, v) => MapEntry(k.toString(), v == true));
  }

  Future<void> toggleSchoolFeature(String schoolId, String featureKey, bool enabled) async {
    await _dio.put(
      '$_basePath/features/school/$schoolId/$featureKey',
      data: {'is_enabled': enabled},
    );
  }

  // ── Hardware ─────────────────────────────────────────────────────────────
  Future<PaginationModel<SuperAdminHardwareDeviceModel>> getHardware({
    String? schoolId,
    String? type,
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final q = <String, String>{'page': page.toString(), 'limit': limit.toString()};
    if (schoolId != null && schoolId.isNotEmpty) q['school_id'] = schoolId;
    if (type != null && type.isNotEmpty) q['device_type'] = type;
    if (status != null && status.isNotEmpty) q['status'] = status;
    if (search != null && search.isNotEmpty) q['search'] = search;

    final res = await _dio.get('$_basePath/hardware', queryParameters: q);
    final raw = res.data;
    final payload = raw is Map && raw['data'] is Map
        ? raw['data'] as Map<String, dynamic>
        : (raw is Map ? raw as Map<String, dynamic> : {'data': [], 'pagination': {}});
    return PaginationModel.fromJson(
      payload,
      (j) => SuperAdminHardwareDeviceModel.fromJson(j),
    );
  }

  Future<void> registerHardware(Map<String, dynamic> body) async {
    await _dio.post('$_basePath/hardware', data: body);
  }

  Future<void> updateHardware(String id, Map<String, dynamic> body) async {
    await _dio.put('$_basePath/hardware/$id', data: body);
  }

  Future<void> pingDevice(String id) async {
    await _dio.put('$_basePath/hardware/$id/ping');
  }

  Future<void> alertSchool(String id, {String? message}) async {
    await _dio.post('$_basePath/hardware/$id/alert-school', data: {
      'message': message ?? 'Your device is offline',
    });
  }

  Future<void> deleteDevice(String id) async {
    await _dio.delete('$_basePath/hardware/$id');
  }

  // ── Admins ───────────────────────────────────────────────────────────────
  Future<List<SuperAdminUserModel>> getSuperAdmins() async {
    final res = await _dio.get('$_basePath/admins');
    final list = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (list is! List) return [];
    return list
        .map((e) => SuperAdminUserModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<void> addSuperAdmin(Map<String, dynamic> body) async {
    await _dio.post('$_basePath/admins', data: body);
  }

  Future<void> updateSuperAdmin(String id, Map<String, dynamic> body) async {
    await _dio.put('$_basePath/admins/$id', data: body);
  }

  Future<void> removeSuperAdmin(String id) async {
    await _dio.delete('$_basePath/admins/$id');
  }

  Future<void> resetSuperAdminPassword(String id, {String newPassword = 'Password@123'}) async {
    await _dio.put('$_basePath/admins/$id/reset-password', data: {'new_password': newPassword});
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.put('$_basePath/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  // ── Audit Logs ─────────────────────────────────────────────────────────────
  Future<PaginationModel<SuperAdminAuditLogModel>> getAuditLogs(
    String type, {
    int page = 1,
    int limit = 30,
    String? search,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final q = <String, String>{'page': page.toString(), 'limit': limit.toString()};
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (dateFrom != null) q['date_from'] = dateFrom.toIso8601String();
    if (dateTo != null) q['date_to'] = dateTo.toIso8601String();

    final res = await _dio.get('$_basePath/audit/$type', queryParameters: q);
    final raw = res.data;
    final payload = raw is Map && raw['data'] is Map
        ? raw['data'] as Map<String, dynamic>
        : (raw is Map ? raw as Map<String, dynamic> : {'data': [], 'pagination': {}});
    return PaginationModel.fromJson(
      payload,
      (j) => SuperAdminAuditLogModel.fromJson(j),
    );
  }

  // ── Security ─────────────────────────────────────────────────────────────
  Future<List<SuperAdminAuditLogModel>> getSecurityEvents() async {
    final res = await _dio.get('$_basePath/security/events');
    final list = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (list is! List) return [];
    return list
        .map((e) => SuperAdminAuditLogModel.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getTrustedDevices() async {
    final res = await _dio.get('$_basePath/security/trusted-devices');
    final list = res.data is Map ? res.data['data'] ?? res.data : res.data;
    if (list is! List) return [];
    return list.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList();
  }

  Future<void> revokeDevice(String deviceId) async {
    await _dio.delete('$_basePath/security/trusted-devices/$deviceId');
  }

  Future<void> blockIp(String ip, String reason) async {
    await _dio.post('$_basePath/security/block-ip', data: {'ip_address': ip, 'reason': reason});
  }

  // ── 2FA ────────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> get2faStatus() async {
    final res = await _dio.get('$_basePath/security/2fa/status');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<Map<String, dynamic>> setup2fa() async {
    final res = await _dio.post('$_basePath/security/2fa/setup');
    final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
    return data is Map<String, dynamic> ? data : {};
  }

  Future<void> enable2fa(String totpCode) async {
    await _dio.post('$_basePath/security/2fa/enable', data: {'totp_code': totpCode});
  }

  Future<void> disable2fa(String password) async {
    await _dio.post('$_basePath/security/2fa/disable', data: {'password': password});
  }

  // ── Infra ─────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getInfraStatus() async {
    final res = await _dio.get('$_basePath/infra/status');
    return res.data is Map<String, dynamic> ? res.data : {};
  }

  // ── Notifications ───────────────────────────────────────────────────────
  Future<int> getUnreadNotificationCount() async {
    try {
      final res = await _dio.get('$_basePath/notifications/unread-count');
      final data = res.data is Map ? res.data['data'] ?? res.data : res.data;
      if (data is Map && data['count'] != null) {
        return (data['count'] as num).toInt();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    final res = await _dio.get('$_basePath/notifications', queryParameters: {'page': page, 'limit': limit});
    final raw = res.data;
    return raw is Map<String, dynamic> ? raw : {'data': [], 'pagination': {}};
  }

  Future<void> markNotificationRead(String id) async {
    await _dio.put('$_basePath/notifications/$id/read');
  }

  Future<void> markAllNotificationsRead() async {
    await _dio.put('$_basePath/notifications/mark-all-read');
  }
}

final superAdminServiceProvider = Provider<SuperAdminService>((ref) {
  return SuperAdminService(ref.read(dioProvider));
});
