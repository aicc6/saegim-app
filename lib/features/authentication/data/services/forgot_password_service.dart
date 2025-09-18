import 'package:dio/dio.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/features/authentication/data/models/forgot_password_models.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 비밀번호 찾기 API 서비스
class ForgotPasswordService {
  static const String _baseUrl = '/api/auth';
  static final Dio _dio = DioClient.instance.dio;

  /// 비밀번호 재설정 이메일 발송
  /// 
  /// [email] 비밀번호를 재설정할 이메일 주소
  /// 
  /// Returns [PasswordResetEmailResponse] 이메일 발송 결과
  /// Throws [DioException] API 호출 실패 시
  static Future<PasswordResetEmailResponse> sendPasswordResetEmail(
    String email,
  ) async {
    try {
      AppLogger.info('Sending password reset email to: $email');

      final request = PasswordResetEmailRequest(email: email);
      final response = await _dio.post(
        '$_baseUrl/forgot-password',
        data: request.toJson(),
      );

      AppLogger.info(
        'Password reset email response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        final baseResponse = BaseResponse<PasswordResetEmailResponse>.fromJson(
          response.data,
          (data) => PasswordResetEmailResponse.fromJson(data),
        );

        if (baseResponse.data != null) {
          AppLogger.info(
            'Password reset email sent successfully to: $email',
          );
          return baseResponse.data!;
        } else {
          // data가 null인 경우 기본 응답 생성
          return PasswordResetEmailResponse(
            success: baseResponse.success,
            message: baseResponse.message,
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
      AppLogger.error(
        'Failed to send password reset email to: $email',
        error: e,
      );

      // API 에러 응답 처리
      if (e.response != null) {
        final errorData = e.response!.data;
        if (errorData is Map<String, dynamic>) {
          final message = errorData['message'] as String? ?? 
                         errorData['detail'] as String? ?? 
                         '이메일 발송에 실패했습니다.';
          
          return PasswordResetEmailResponse(
            success: false,
            message: message,
          );
        }
      }

      // 네트워크 에러나 기타 에러
      String errorMessage = '이메일 발송에 실패했습니다.';
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '네트워크 연결이 불안정합니다. 다시 시도해주세요.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      }

      return PasswordResetEmailResponse(
        success: false,
        message: errorMessage,
      );
    } catch (e) {
      AppLogger.error(
        'Unexpected error sending password reset email to: $email',
        error: e,
      );

      return const PasswordResetEmailResponse(
        success: false,
        message: '알 수 없는 오류가 발생했습니다.',
      );
    }
  }

  /// 비밀번호 재설정 인증코드 확인
  /// 
  /// [email] 이메일 주소
  /// [verificationCode] 인증코드
  /// 
  /// Returns [bool] 인증코드 검증 성공 여부
  /// Throws [DioException] API 호출 실패 시
  static Future<bool> verifyPasswordResetCode(
    String email,
    String verificationCode,
  ) async {
    try {
      AppLogger.info(
        'Verifying password reset code for email: $email',
      );

      final request = VerifyPasswordResetCodeRequest(
        email: email,
        verificationCode: verificationCode,
      );

      final response = await _dio.post(
        '$_baseUrl/forgot-password/verify',
        data: request.toJson(),
      );

      AppLogger.info(
        'Password reset code verification response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        final baseResponse = BaseResponse<Map<String, dynamic>>.fromJson(
          response.data,
          (data) => data as Map<String, dynamic>,
        );

        AppLogger.info(
          'Password reset code verified successfully for email: $email',
        );
        return baseResponse.success;
      } else {
        AppLogger.warning(
          'Password reset code verification failed with status: ${response.statusCode}',
        );
        return false;
      }
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to verify password reset code for email: $email',
        error: e,
      );

      // 400, 401, 422 등의 에러는 인증코드가 잘못된 것으로 처리
      if (e.response?.statusCode == 400 || 
          e.response?.statusCode == 401 || 
          e.response?.statusCode == 422) {
        return false;
      }

      rethrow;
    } catch (e) {
      AppLogger.error(
        'Unexpected error verifying password reset code for email: $email',
        error: e,
      );
      rethrow;
    }
  }

  /// 비밀번호 재설정
  /// 
  /// [email] 이메일 주소
  /// [verificationCode] 인증코드
  /// [newPassword] 새로운 비밀번호
  /// 
  /// Returns [bool] 비밀번호 재설정 성공 여부
  /// Throws [DioException] API 호출 실패 시
  static Future<bool> resetPassword(
    String email,
    String verificationCode,
    String newPassword,
  ) async {
    try {
      AppLogger.info(
        'Resetting password for email: $email',
      );

      final request = ResetPasswordRequest(
        email: email,
        verificationCode: verificationCode,
        newPassword: newPassword,
      );

      final response = await _dio.post(
        '$_baseUrl/forgot-password/reset',
        data: request.toJson(),
      );

      AppLogger.info(
        'Password reset response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        final baseResponse = BaseResponse<Map<String, String>>.fromJson(
          response.data,
          (data) => Map<String, String>.from(data as Map),
        );

        AppLogger.info(
          'Password reset successfully for email: $email',
        );
        return baseResponse.success;
      } else {
        AppLogger.warning(
          'Password reset failed with status: ${response.statusCode}',
        );
        return false;
      }
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to reset password for email: $email',
        error: e,
      );

      // 400, 401, 422 등의 에러는 요청이 잘못된 것으로 처리
      if (e.response?.statusCode == 400 || 
          e.response?.statusCode == 401 || 
          e.response?.statusCode == 422) {
        return false;
      }

      rethrow;
    } catch (e) {
      AppLogger.error(
        'Unexpected error resetting password for email: $email',
        error: e,
      );
      rethrow;
    }
  }

  /// 이메일 형식 검증
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// 비밀번호 강도 검증
  static bool isValidPassword(String password) {
    // 최소 8자, 영문자와 숫자 포함
    return password.length >= 8 && 
           RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password);
  }

  /// 인증코드 형식 검증 (6자리 숫자)
  static bool isValidVerificationCode(String code) {
    return RegExp(r'^\d{6}$').hasMatch(code);
  }
}