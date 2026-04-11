// =============================================================================
// FILE: lib/core/services/profile_request_service.dart
// PURPOSE: API service for student profile update requests.
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../network/dio_client.dart';
import '../../models/school_admin/profile_update_request_model.dart';

/// Paginated result for profile requests.
class ProfileRequestPageResult {
  final List<ProfileUpdateRequest> requests;
  final int total;
  final int page;
  final int totalPages;

  const ProfileRequestPageResult({
    required this.requests,
    required this.total,
    required this.page,
    required this.totalPages,
  });
}

class ProfileRequestService {
  ProfileRequestService(this._dio);

  final Dio _dio;

  // ── School Admin / Staff endpoints ────────────────────────────────────────

  Future<ProfileRequestPageResult> fetchSchoolProfileRequests({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final res = await _dio.get(
      ApiConfig.schoolProfileRequests,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final raw = res.data;
    if (raw is! Map) {
      return const ProfileRequestPageResult(
        requests: [],
        total: 0,
        page: 1,
        totalPages: 1,
      );
    }
    final data = raw['data'];
    dynamic list;
    int total = 0;
    int totalPages = 1;
    if (data is Map) {
      list = data['data'] ?? data['requests'] ?? data;
      total = (data['total'] as num?)?.toInt() ?? 0;
      totalPages = (data['total_pages'] as num?)?.toInt() ?? 1;
    } else if (data is List) {
      list = data;
      total = data.length;
    } else {
      list = raw['requests'] ?? [];
    }
    if (list is! List) {
      return const ProfileRequestPageResult(
        requests: [],
        total: 0,
        page: 1,
        totalPages: 1,
      );
    }
    final requests = list
        .map((e) => ProfileUpdateRequest.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
    return ProfileRequestPageResult(
      requests: requests,
      total: total,
      page: page,
      totalPages: totalPages > 0 ? totalPages : 1,
    );
  }

  Future<int> fetchPendingCount() async {
    final res = await _dio.get(ApiConfig.schoolProfileRequestsPendingCount);
    final raw = res.data;
    if (raw is Map) {
      final data = raw['data'];
      if (data is Map && data['count'] != null) {
        return (data['count'] as num).toInt();
      }
      if (data is num) return data.toInt();
    }
    return 0;
  }

  Future<void> approveRequest(String requestId, {String? note}) async {
    await _dio.post(
      '${ApiConfig.schoolProfileRequests}/$requestId/approve',
      data: {
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  Future<void> rejectRequest(String requestId, {required String note}) async {
    await _dio.post(
      '${ApiConfig.schoolProfileRequests}/$requestId/reject',
      data: {'note': note},
    );
  }

  // ── Parent endpoints ──────────────────────────────────────────────────────

  Future<ProfileRequestPageResult> fetchParentProfileRequests({
    int page = 1,
    int limit = 10,
    String? studentId,
  }) async {
    final res = await _dio.get(
      ApiConfig.parentProfileRequests,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (studentId != null && studentId.isNotEmpty) 'studentId': studentId,
      },
    );
    final raw = res.data;
    if (raw is! Map) {
      return const ProfileRequestPageResult(
        requests: [],
        total: 0,
        page: 1,
        totalPages: 1,
      );
    }
    final data = raw['data'];
    dynamic list;
    int total = 0;
    int totalPages = 1;
    if (data is Map) {
      list = data['data'] ?? data['requests'] ?? data;
      total = (data['total'] as num?)?.toInt() ?? 0;
      totalPages = (data['total_pages'] as num?)?.toInt() ?? 1;
    } else if (data is List) {
      list = data;
      total = data.length;
    } else {
      list = raw['requests'] ?? [];
    }
    if (list is! List) {
      return const ProfileRequestPageResult(
        requests: [],
        total: 0,
        page: 1,
        totalPages: 1,
      );
    }
    final requests = list
        .map((e) => ProfileUpdateRequest.fromJson(
              e is Map<String, dynamic> ? e : {},
            ))
        .toList();
    return ProfileRequestPageResult(
      requests: requests,
      total: total,
      page: page,
      totalPages: totalPages > 0 ? totalPages : 1,
    );
  }

  Future<Map<String, dynamic>> submitProfileUpdateRequest({
    required String studentId,
    required Map<String, dynamic> requestedChanges,
  }) async {
    final res = await _dio.post(
      ApiConfig.parentProfileRequests,
      data: {
        'studentId': studentId,
        'requestedChanges': requestedChanges,
      },
    );
    final raw = res.data;
    if (raw is Map && raw['data'] is Map) {
      return raw['data'] as Map<String, dynamic>;
    }
    if (raw is Map<String, dynamic>) return raw;
    return {};
  }
}

final profileRequestServiceProvider = Provider<ProfileRequestService>((ref) {
  return ProfileRequestService(ref.read(dioProvider));
});
