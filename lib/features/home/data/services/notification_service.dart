import 'package:dio/dio.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/features/home/data/models/notification_model.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 알림 관련 API 서비스
class NotificationService {
  late final Dio _dio;

  NotificationService() {
    _dio = DioClient.create();
  }

  /// 알림 히스토리 조회
  ///
  /// [limit] 조회할 알림 개수 (기본값: 20, 최대: 100)
  /// [offset] 건너뛸 알림 개수 (기본값: 0)
  Future<NotificationHistoryResponse> getNotificationHistory({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      AppLogger.info(
        'Fetching notifications: limit=$limit, offset=$offset',
        'NotificationService'
      );

      final response = await _dio.get(
        '/api/notifications/history',
        queryParameters: {
          'limit': limit.clamp(1, 100), // 1-100 범위로 제한
          'offset': offset.clamp(0, double.maxFinite.toInt()),
        },
      );

      if (response.statusCode == 200) {
        // 응답 데이터 타입과 구조 로깅
        AppLogger.info('Notification API response type: ${response.data.runtimeType}');
        AppLogger.info('Notification API response data: ${response.data}');
        
        // 안전한 타입 체크
        if (response.data is! Map<String, dynamic>) {
          AppLogger.error('Expected Map<String, dynamic> but got ${response.data.runtimeType}');
          throw Exception('서버 응답 형식이 올바르지 않습니다.');
        }
        
        final responseData = response.data as Map<String, dynamic>;
        
        // success가 true인지 확인
        if (responseData['success'] == true) {
          final data = responseData['data'];
          
          // data가 빈 배열인 경우 빈 NotificationHistoryResponse 생성
          if (data is List && data.isEmpty) {
            AppLogger.info('No notifications found - returning empty result', 'NotificationService');
            return const NotificationHistoryResponse(
              notifications: [],
              total: 0,
              unreadCount: 0,
              hasMore: false,
            );
          }
          
          // data가 배열인 경우 (실제 서버 응답 구조)
          if (data is List) {
            final notifications = data.map((item) => NotificationItem.fromJson(item as Map<String, dynamic>)).toList();
            AppLogger.info('Successfully fetched ${notifications.length} notifications', 'NotificationService');
            
            // NotificationHistoryResponse 구조로 변환
            return NotificationHistoryResponse(
              notifications: notifications,
              total: notifications.length,
              unreadCount: notifications.where((n) => !n.isRead).length,
              hasMore: false, // TODO: 페이지네이션 정보가 있다면 서버에서 받아와야 함
            );
          }
          
          // data가 Map인 경우 (기존 구조)
          if (data is Map<String, dynamic>) {
            final notificationHistory = NotificationHistoryResponse.fromJson(data);
            AppLogger.info(
              'Successfully fetched ${notificationHistory.notifications.length} notifications',
              'NotificationService'
            );
            return notificationHistory;
          }
          
          // 예상치 못한 data 형식
          AppLogger.error('Unexpected data format: ${data.runtimeType} - $data');
          throw Exception('서버 응답의 데이터 형식이 올바르지 않습니다.');
        } else {
          // success가 false인 경우
          final error = responseData['message'] ?? '알림을 불러오는데 실패했습니다.';
          throw Exception(error);
        }
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to fetch notifications',
        error: e,
        tag: 'NotificationService'
      );

      String errorMessage = '알림을 불러오는데 실패했습니다.';

      if (e.response?.statusCode == 401) {
        errorMessage = '인증이 필요합니다. 다시 로그인해주세요.';
      } else if (e.response?.statusCode == 403) {
        errorMessage = '알림에 접근할 권한이 없습니다.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = '알림 서비스를 찾을 수 없습니다.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '네트워크 연결이 불안정합니다. 다시 시도해주세요.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '인터넷 연결을 확인해주세요.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      AppLogger.error(
        'Unexpected error while fetching notifications',
        error: e,
        tag: 'NotificationService'
      );
      throw Exception('알림을 불러오는 중 예상치 못한 오류가 발생했습니다.');
    }
  }

  /// 특정 알림을 읽음 처리
  ///
  /// [notificationId] 읽음 처리할 알림 ID (UUID String)
  Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      AppLogger.info(
        'Marking notification as read: $notificationId',
        'NotificationService'
      );

      final response = await _dio.patch(
        '/api/notifications/$notificationId/read',
      );

      if (response.statusCode == 200) {
        AppLogger.info(
          'Successfully marked notification $notificationId as read',
          'NotificationService'
        );
        return true;
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to mark notification as read: $notificationId',
        error: e,
        tag: 'NotificationService'
      );

      String errorMessage = '알림을 읽음 처리하는데 실패했습니다.';

      if (e.response?.statusCode == 401) {
        errorMessage = '인증이 필요합니다. 다시 로그인해주세요.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = '알림을 찾을 수 없습니다.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      AppLogger.error(
        'Unexpected error while marking notification as read',
        error: e,
        tag: 'NotificationService'
      );
      throw Exception('알림 읽음 처리 중 예상치 못한 오류가 발생했습니다.');
    }
  }

  /// 모든 알림을 읽음 처리
  Future<bool> markAllNotificationsAsRead() async {
    try {
      AppLogger.info('Marking all notifications as read', 'NotificationService');

      final response = await _dio.patch('/api/notifications/read-all');

      if (response.statusCode == 200) {
        AppLogger.info(
          'Successfully marked all notifications as read',
          'NotificationService'
        );
        return true;
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to mark all notifications as read',
        error: e,
        tag: 'NotificationService'
      );

      String errorMessage = '모든 알림을 읽음 처리하는데 실패했습니다.';

      if (e.response?.statusCode == 401) {
        errorMessage = '인증이 필요합니다. 다시 로그인해주세요.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      AppLogger.error(
        'Unexpected error while marking all notifications as read',
        error: e,
        tag: 'NotificationService'
      );
      throw Exception('알림 읽음 처리 중 예상치 못한 오류가 발생했습니다.');
    }
  }

  /// 특정 알림 삭제
  ///
  /// [notificationId] 삭제할 알림 ID (UUID String)
  Future<bool> deleteNotification(String notificationId) async {
    try {
      AppLogger.info(
        'Deleting notification: $notificationId',
        'NotificationService'
      );

      final response = await _dio.delete(
        '/api/notifications/$notificationId',
      );

      if (response.statusCode == 200) {
        AppLogger.info(
          'Successfully deleted notification $notificationId',
          'NotificationService'
        );
        return true;
      } else {
        throw Exception('서버 오류: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error(
        'Failed to delete notification: $notificationId',
        error: e,
        tag: 'NotificationService'
      );

      String errorMessage = '알림을 삭제하는데 실패했습니다.';

      if (e.response?.statusCode == 401) {
        errorMessage = '인증이 필요합니다. 다시 로그인해주세요.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = '알림을 찾을 수 없습니다.';
      }

      throw Exception(errorMessage);
    } catch (e) {
      AppLogger.error(
        'Unexpected error while deleting notification',
        error: e,
        tag: 'NotificationService'
      );
      throw Exception('알림 삭제 중 예상치 못한 오류가 발생했습니다.');
    }
  }
}