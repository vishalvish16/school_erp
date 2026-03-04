// =============================================================================
// FILE: lib/core/network/dio_client.dart
// PURPOSE: Global Dio instance provider with base configurations
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/api_config.dart';
import '../../features/auth/auth_guard_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      contentType: 'application/json',
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  // Add auth interceptor to properly inject JWT bearer token into every active Riverpod request natively
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authGuardProvider).accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Here we could implement automatic token refresh interceptor later
        return handler.next(e);
      },
    ),
  );

  // Add logging interceptor for development (optional)
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
    ),
  );

  return dio;
});
