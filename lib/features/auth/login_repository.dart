// =============================================================================
// FILE: lib/features/auth/login_repository.dart
// PURPOSE: Repository for Super Admin Login using Dio for HTTP calls
// =============================================================================

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/dio_client.dart';

/// Abstract interface for Login operations
abstract class LoginRepository {
  Future<String> login(String email, String password);
}

/// Production implementation using Dio
class AuthRepository implements LoginRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<String> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConfig.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // successResponse payload contains { success: true, data: { access_token } }
        final data = response.data['data'];
        if (data != null && data['access_token'] != null) {
          return data['access_token'];
        }
        throw Exception('Access token missing from response payload');
      } else if (response.statusCode == 401) {
        throw Exception('Invalid email or password. Access denied.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Connection timed out. Please check your internet.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network unreachable. Please try again later.');
      } else {
        throw Exception(e.message ?? 'An unexpected network error occurred.');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
}

/// Mock implementation for local testing without backend
class MockLoginRepository implements LoginRepository {
  @override
  Future<String> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 2));
    if (email == 'vishal.vish16@gmail.com' && password == 'password123') {
      return 'mock_jwt_token_123';
    } else {
      throw Exception('Invalid demo credentials. Use vishal.vish16@gmail.com');
    }
  }
}

/// Toggle this to use real API or Mock
const bool useMockAuth = false;

/// Provider to switch between mock and real repository
final loginRepositoryProvider = Provider<LoginRepository>((ref) {
  if (useMockAuth) {
    return MockLoginRepository();
  }
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});
