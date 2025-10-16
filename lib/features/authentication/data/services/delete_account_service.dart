import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 계정 탈퇴 API 서비스
class DeleteAccountService {
  static String get _baseUrl => '${dotenv.env['API_BASE_URL']}/api/auth';
  static final Dio _dio = DioClient.instance.dio;

  /// 계정 탈퇴
  ///
  /// [password] 현재 비밀번호 (본인 확인용)
  /// [reason] 탈퇴 사유 (선택사항)
  ///
  /// Returns [bool] 계정 탈퇴 성공 여부
  /// Throws [DioException] API 호출 실패 시
  static Future<bool> deleteAccount({
    String? password,
    String? reason,
  }) async {
    try {
      AppLogger.info('Attempting to delete user account');

      final response = await _dio.delete(
        '$_baseUrl/delete-account',
        data: {
          if (password != null && password.isNotEmpty) 'password': password,
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );

      AppLogger.info(
        'Account deletion response: ${response.statusCode} - ${response.data}',
      );

      if (response.statusCode == 200) {
        AppLogger.info('Account deleted successfully');
        return true;
      } else {
        AppLogger.warning(
          'Account deletion failed with status: ${response.statusCode}',
        );
        return false;
      }
    } on DioException catch (e) {
      AppLogger.error('Failed to delete account', error: e);

      // 401은 비밀번호가 잘못된 경우
      if (e.response?.statusCode == 401) {
        throw DeleteAccountException('비밀번호가 올바르지 않습니다.');
      }

      // 403은 권한이 없는 경우 (이미 탈퇴된 계정 등)
      if (e.response?.statusCode == 403) {
        throw DeleteAccountException('계정 탈퇴 권한이 없습니다.');
      }

      // 422는 유효성 검사 실패
      if (e.response?.statusCode == 422) {
        final errorData = e.response?.data;
        if (errorData is Map<String, dynamic>) {
          final message =
              errorData['message'] as String? ??
              errorData['detail'] as String? ??
              '입력한 정보가 올바르지 않습니다.';
          throw DeleteAccountException(message);
        }
        throw DeleteAccountException('입력한 정보가 올바르지 않습니다.');
      }

      // 네트워크 에러
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw DeleteAccountException('네트워크 연결이 불안정합니다. 다시 시도해주세요.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw DeleteAccountException('네트워크 연결을 확인해주세요.');
      }

      throw DeleteAccountException('계정 탈퇴에 실패했습니다.');
    } catch (e) {
      AppLogger.error('Unexpected error deleting account', error: e);

      if (e is DeleteAccountException) {
        rethrow;
      }

      throw DeleteAccountException('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 탈퇴 사유 목록
  static const List<String> deletionReasons = [
    '서비스를 더 이상 사용하지 않음',
    '개인정보 보호 우려',
    '다른 서비스로 이동',
    '기능이 부족함',
    '서비스 품질 불만족',
    '기타',
  ];

  /// 탈퇴 전 안내사항
  static const List<String> deletionWarnings = [
    '계정 탈퇴 후 30일간 데이터가 보관됩니다.',
    '30일 이내에 같은 이메일로 로그인하면 자동으로 복구됩니다.',
    '30일 후에는 모든 데이터가 영구적으로 삭제됩니다.',
    '탈퇴 기간 중에는 새김 서비스를 이용할 수 없습니다.',
  ];
}

/// 계정 탈퇴 관련 예외
class DeleteAccountException implements Exception {
  final String message;

  const DeleteAccountException(this.message);

  @override
  String toString() => message;
}
