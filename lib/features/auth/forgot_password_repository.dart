import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/api_config.dart';
import '../../core/network/dio_client.dart';

abstract class ForgotPasswordRepository {
  Future<void> sendResetLink(String email);
  Future<void> resetPassword(String token, String newPassword);
}

class ApiForgotPasswordRepository implements ForgotPasswordRepository {
  ApiForgotPasswordRepository(this._dio);
  final Dio _dio;

  @override
  Future<void> sendResetLink(String email) async {
    try {
      await _dio.post(ApiConfig.forgotPasswordEndpoint, data: {'email': email});
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to send reset link',
      );
    }
  }

  @override
  Future<void> resetPassword(String token, String newPassword) async {
    try {
      await _dio.post(
        ApiConfig.resetPasswordEndpoint,
        data: {'token': token, 'newPassword': newPassword},
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to reset password',
      );
    }
  }
}

final forgotPasswordRepositoryProvider = Provider<ForgotPasswordRepository>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return ApiForgotPasswordRepository(dio);
});
