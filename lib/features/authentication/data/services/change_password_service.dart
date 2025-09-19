import 'package:dio/dio.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 로그인한 사용자 비밀번호 변경 API 서비스
class ChangePasswordService {
  static const String _baseUrl = '/api/auth';
  static final Dio _dio = DioClient.instance.dio;

  /// 비밀번호 변경
  ///
  /// [currentPassword] 현재 비밀번호
  /// [newPassword] 새로운 비밀번호
  ///
  /// Returns [bool] 비밀번호 변경 성공 여부
  /// Throws [DioException] API 호출 실패 시
  static Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      AppLogger.info('Changing password for authenticated user');

      final response = await _dio.post(
        '$_baseUrl/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      AppLogger.info(
        'Password change response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        AppLogger.info('Password changed successfully');
        return true;
      } else {
        AppLogger.warning(
          'Password change failed with status: ${response.statusCode}',
        );
        return false;
      }
    } on DioException catch (e) {
      AppLogger.error('Failed to change password', error: e);

      // 401은 현재 비밀번호가 잘못된 경우
      if (e.response?.statusCode == 401) {
        throw ChangePasswordException('현재 비밀번호가 올바르지 않습니다.');
      }

      // 422는 유효성 검사 실패
      if (e.response?.statusCode == 422) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final message =
              errorData['message'] as String? ??
              errorData['detail'] as String? ??
              '비밀번호 형식이 올바르지 않습니다.';
          throw ChangePasswordException(message);
        }
        throw ChangePasswordException('비밀번호 형식이 올바르지 않습니다.');
      }

      // 네트워크 에러
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw ChangePasswordException('네트워크 연결이 불안정합니다. 다시 시도해주세요.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw ChangePasswordException('네트워크 연결을 확인해주세요.');
      }

      throw ChangePasswordException('비밀번호 변경에 실패했습니다.');
    } catch (e) {
      AppLogger.error('Unexpected error changing password', error: e);

      if (e is ChangePasswordException) {
        rethrow;
      }

      throw ChangePasswordException('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 비밀번호 강도 검증
  static bool isValidPassword(String password) {
    // 최소 8자, 영문자와 숫자 포함
    return password.length >= 8 &&
        RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password);
  }

  /// 비밀번호 강도 검증 메시지
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return '비밀번호를 입력해주세요.';
    }
    if (password.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다.';
    }
    if (!RegExp(r'^(?=.*[A-Za-z])').hasMatch(password)) {
      return '비밀번호에 영문자를 포함해주세요.';
    }
    if (!RegExp(r'^(?=.*\d)').hasMatch(password)) {
      return '비밀번호에 숫자를 포함해주세요.';
    }
    return null;
  }
}

/// 비밀번호 변경 관련 예외
class ChangePasswordException implements Exception {
  final String message;

  const ChangePasswordException(this.message);

  @override
  String toString() => message;
}
