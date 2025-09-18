import 'package:dio/dio.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 비밀번호 변경 서비스
class ChangePasswordService {
  static const String _baseUrl = '/api/auth';
  static final Dio _dio = DioClient.instance.dio;

  /// 비밀번호 변경
  /// 
  /// [currentPassword] 현재 비밀번호
  /// [newPassword] 새로운 비밀번호
  /// 
  /// Returns [ChangePasswordResponse] 비밀번호 변경 결과
  /// Throws [DioException] API 호출 실패 시
  static Future<ChangePasswordResponse> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      AppLogger.info('Attempting to change password');

      final request = ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      // 요청 데이터 로깅
      final requestData = request.toJson();
      AppLogger.info('🔐 Password change request data: $requestData');
      AppLogger.info('🌐 Request URL: $_baseUrl/change-password');
      AppLogger.info('📤 Current password length: ${currentPassword.length}');
      AppLogger.info('📤 New password length: ${newPassword.length}');

      final response = await _dio.post(
        '$_baseUrl/change-password',
        data: requestData,
      );

      // 응답 데이터 상세 로깅
      AppLogger.info('📥 Response status code: ${response.statusCode}');
      AppLogger.info('📥 Response headers: ${response.headers}');
      AppLogger.info('📥 Response data: ${response.data}');
      AppLogger.info('📥 Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final baseResponse = BaseResponse<ChangePasswordResponse>.fromJson(
          response.data,
          (data) => ChangePasswordResponse.fromJson(data),
        );

        if (baseResponse.success) {
          AppLogger.info('Password changed successfully');
          return baseResponse.data ?? ChangePasswordResponse(
            success: true,
            message: baseResponse.message ?? '비밀번호가 성공적으로 변경되었습니다.',
          );
        } else {
          AppLogger.warning('Password change failed: ${baseResponse.message}');
          return ChangePasswordResponse(
            success: false,
            message: baseResponse.message ?? '비밀번호 변경에 실패했습니다.',
          );
        }
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      // 에러 상세 로깅
      AppLogger.error('❌ DioException occurred during password change');
      AppLogger.error('❌ Error type: ${e.type}');
      AppLogger.error('❌ Error message: ${e.message}');
      AppLogger.error('❌ Response status code: ${e.response?.statusCode}');
      AppLogger.error('❌ Response data: ${e.response?.data}');
      AppLogger.error('❌ Response headers: ${e.response?.headers}');
      AppLogger.error('❌ Request data: ${e.requestOptions.data}');
      AppLogger.error('❌ Request path: ${e.requestOptions.path}');

      // API 에러 응답 처리
      if (e.response != null) {
        final errorData = e.response!.data;
        AppLogger.error('❌ Processing error response data: $errorData');
        AppLogger.error('❌ Error data type: ${errorData.runtimeType}');
        
        if (errorData is Map<String, dynamic>) {
          final message = errorData['message'] as String? ?? 
                         errorData['detail'] as String? ?? 
                         '비밀번호 변경에 실패했습니다.';
          
          AppLogger.error('❌ Extracted error message: $message');
          
          return ChangePasswordResponse(
            success: false,
            message: message,
          );
        }
      }

      // 네트워크 에러나 기타 에러
      String errorMessage = '비밀번호 변경에 실패했습니다.';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '네트워크 연결이 불안정합니다. 다시 시도해주세요.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      }

      return ChangePasswordResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      AppLogger.error('Unexpected error changing password', error: e);

      return const ChangePasswordResponse(
        success: false,
        message: '알 수 없는 오류가 발생했습니다.',
      );
    }
  }

  /// 현재 비밀번호 확인
  /// 
  /// [password] 확인할 비밀번호
  /// 
  /// Returns [bool] 비밀번호 확인 결과
  /// Throws [DioException] API 호출 실패 시
  static Future<bool> verifyCurrentPassword(String password) async {
    try {
      AppLogger.info('Verifying current password');

      final request = VerifyPasswordRequest(currentPassword: password);

      final response = await _dio.post(
        '$_baseUrl/verify-password',
        data: request.toJson(),
      );

      AppLogger.info(
        'Verify password response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        final baseResponse = BaseResponse<Map<String, dynamic>>.fromJson(
          response.data,
          (data) => data,
        );

        AppLogger.info('Password verification result: ${baseResponse.success}');
        return baseResponse.success;
      } else {
        AppLogger.warning(
          'Password verification failed with status: ${response.statusCode}',
        );
        return false;
      }
    } on DioException catch (e) {
      AppLogger.error('Failed to verify password', error: e);

      // 401 Unauthorized는 비밀번호가 틀린 것으로 처리
      if (e.response?.statusCode == 401) {
        return false;
      }

      rethrow;
    } catch (e) {
      AppLogger.error('Unexpected error verifying password', error: e);
      rethrow;
    }
  }

  /// 비밀번호 강도 검증
  static bool isValidPassword(String password) {
    // 최소 8자, 영문자와 숫자 포함
    return password.length >= 8 && 
           RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password);
  }

  /// 비밀번호 강도 검증 (상세)
  static PasswordValidation validatePassword(String password) {
    final validations = <String>[];
    
    if (password.length < 8) {
      validations.add('최소 8자 이상이어야 합니다');
    }
    
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      validations.add('영문자를 포함해야 합니다');
    }
    
    if (!RegExp(r'\d').hasMatch(password)) {
      validations.add('숫자를 포함해야 합니다');
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      validations.add('특수문자를 포함하면 더 안전합니다');
    }

    return PasswordValidation(
      isValid: validations.isEmpty || 
               (password.length >= 8 && 
                RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password)),
      errors: validations,
    );
  }
}

/// 비밀번호 변경 요청 모델
class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_password': currentPassword,
      'new_password': newPassword,
    };
  }
}

/// 비밀번호 변경 응답 모델
class ChangePasswordResponse {
  final bool success;
  final String message;

  const ChangePasswordResponse({
    required this.success,
    required this.message,
  });

  factory ChangePasswordResponse.fromJson(Map<String, dynamic> json) {
    return ChangePasswordResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}

/// 비밀번호 확인 요청 모델
class VerifyPasswordRequest {
  final String currentPassword;

  const VerifyPasswordRequest({required this.currentPassword});

  Map<String, dynamic> toJson() {
    return {'current_password': currentPassword};
  }
}

/// 비밀번호 검증 결과 모델
class PasswordValidation {
  final bool isValid;
  final List<String> errors;

  const PasswordValidation({
    required this.isValid,
    required this.errors,
  });
}

/// Base Response 모델 (다른 곳에서 정의되어 있을 수 있지만 임시로 추가)
class BaseResponse<T> {
  final bool success;
  final String? message;
  final T? data;

  const BaseResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return BaseResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}