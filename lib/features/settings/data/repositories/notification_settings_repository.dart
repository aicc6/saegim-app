import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/features/settings/data/models/notification_settings_model.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 알림 설정 관련 API 서비스
class NotificationSettingsRepository {
  late final Dio _dio;

  NotificationSettingsRepository() {
    _dio = DioClient.create();
  }

  /// 알림 설정 조회
  Future<NotificationSettingsModel> getNotificationSettings() async {
    try {
      AppLogger.info('Fetching notification settings', 'NotificationSettingsRepository');

      final response = await _dio.get('/api/notifications/settings');

      if (response.statusCode == 200) {
        if (response.data is! Map<String, dynamic>) {
          throw Exception('서버 응답 형식이 올바르지 않습니다.');
        }

        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          final data = responseData['data'] as Map<String, dynamic>;
          AppLogger.info('Successfully fetched notification settings', 'NotificationSettingsRepository');
          return NotificationSettingsModel.fromJson(data);
        } else {
          final error = responseData['message'] ?? '알림 설정을 불러오는데 실패했습니다.';
          throw Exception(error);
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('Failed to fetch notification settings', error: e, tag: 'NotificationSettingsRepository');

      String errorMessage = '알림 설정을 불러오는데 실패했습니다.';

      if (e.response?.statusCode == 401) {
        errorMessage = '인증이 필요합니다. 다시 로그인해주세요.';
      } else if (e.response?.statusCode == 403) {
        errorMessage = '알림 설정에 접근할 권한이 없습니다.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '네트워크 연결이 불안정합니다. 다시 시도해주세요.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '인터넷 연결을 확인해주세요.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      AppLogger.error('Unexpected error while fetching notification settings', error: e, tag: 'NotificationSettingsRepository');
      throw Exception('알림 설정을 불러오는 중 예상치 못한 오류가 발생했습니다.');
    }
  }

  /// 알림 설정 업데이트
  Future<NotificationSettingsModel> updateNotificationSettings(NotificationSettingsUpdateRequest request) async {
    try {
      AppLogger.info('Updating notification settings', 'NotificationSettingsRepository');

      final response = await _dio.patch(
        '/api/notifications/settings',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        if (response.data is! Map<String, dynamic>) {
          throw Exception('서버 응답 형식이 올바르지 않습니다.');
        }

        final responseData = response.data as Map<String, dynamic>;

        if (responseData['success'] == true) {
          final data = responseData['data'] as Map<String, dynamic>;
          AppLogger.info('Successfully updated notification settings', 'NotificationSettingsRepository');
          return NotificationSettingsModel.fromJson(data);
        } else {
          final error = responseData['message'] ?? '알림 설정 업데이트에 실패했습니다.';
          throw Exception(error);
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error('Failed to update notification settings', error: e, tag: 'NotificationSettingsRepository');

      String errorMessage = '알림 설정 업데이트에 실패했습니다.';

      if (e.response?.statusCode == 401) {
        errorMessage = '인증이 필요합니다. 다시 로그인해주세요.';
      } else if (e.response?.statusCode == 403) {
        errorMessage = '알림 설정을 변경할 권한이 없습니다.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '네트워크 연결이 불안정합니다. 다시 시도해주세요.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '인터넷 연결을 확인해주세요.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      AppLogger.error('Unexpected error while updating notification settings', error: e, tag: 'NotificationSettingsRepository');
      throw Exception('알림 설정 업데이트 중 예상치 못한 오류가 발생했습니다.');
    }
  }
}

/// Provider 정의
final notificationSettingsRepositoryProvider = Provider<NotificationSettingsRepository>((ref) {
  return NotificationSettingsRepository();
});