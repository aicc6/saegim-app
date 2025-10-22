import 'dart:io';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saegim/core/models/app_version.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 앱 버전 관리 서비스
///
/// 백엔드 API를 통해 앱 버전을 체크하고 업데이트를 관리합니다.
class AppVersionService {
  AppVersionService._internal();

  static final AppVersionService _instance = AppVersionService._internal();
  static AppVersionService get instance => _instance;

  late final Dio _dio;
  PackageInfo? _packageInfo;
  CheckAppVersionResponse? _cachedResponse;
  DateTime? _lastCheckedAt;

  /// 초기화 메서드
  Future<void> initialize() async {
    _dio = DioClient.instance.dio;
    _packageInfo = await PackageInfo.fromPlatform();
    AppLogger.info(
      '앱 버전 서비스 초기화: ${_packageInfo?.version}',
      'AppVersionService',
    );
  }

  /// 현재 앱 버전 가져오기
  String get currentVersion => _packageInfo?.version ?? '0.0.0';

  /// 현재 플랫폼 타입 가져오기
  PlatformType get currentPlatform {
    if (Platform.isIOS) {
      return PlatformType.ios;
    } else if (Platform.isAndroid) {
      return PlatformType.android;
    } else {
      throw UnsupportedError('지원하지 않는 플랫폼입니다.');
    }
  }

  /// 앱 버전 체크
  ///
  /// 백엔드 API를 호출하여 최신 버전이 있는지 확인합니다.
  /// Returns: [CheckAppVersionResponse] - 업데이트 정보
  Future<CheckAppVersionResponse> checkAppVersion() async {
    try {
      AppLogger.info(
        '앱 버전 체크 시작: $currentVersion (${currentPlatform.value})',
        'AppVersionService',
      );

      final response = await _dio.post(
        '/api/app-version/check',
        data: {
          'current_version': currentVersion,
          'platform': currentPlatform.value,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final result = CheckAppVersionResponse.fromJson(data);

        AppLogger.info(
          '앱 버전 체크 완료: hasUpdate=${result.hasUpdate}, isMandatory=${result.isMandatory}',
          'AppVersionService',
        );

        _cachedResponse = result;
        _lastCheckedAt = DateTime.now();

        return result;
      } else {
        throw Exception('앱 버전 체크 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error(
        '앱 버전 체크 중 네트워크 오류: ${e.message}',
        tag: 'AppVersionService',
        error: e,
      );
      // 네트워크 오류 시 업데이트 없음으로 처리
      const fallback = CheckAppVersionResponse(
        hasUpdate: false,
        isMandatory: false,
        message: '버전 확인 중 오류가 발생했습니다.',
      );
      _cachedResponse = fallback;
      _lastCheckedAt = DateTime.now();
      return fallback;
    } catch (e) {
      AppLogger.error('앱 버전 체크 중 오류: $e', tag: 'AppVersionService', error: e);
      const fallback = CheckAppVersionResponse(
        hasUpdate: false,
        isMandatory: false,
        message: '버전 확인 중 오류가 발생했습니다.',
      );
      _cachedResponse = fallback;
      _lastCheckedAt = DateTime.now();
      return fallback;
    }
  }

  CheckAppVersionResponse? get cachedResponse => _cachedResponse;

  DateTime? get lastCheckedAt => _lastCheckedAt;

  /// 최신 버전 정보 가져오기
  ///
  /// 현재 플랫폼의 최신 버전 정보를 가져옵니다.
  Future<AppVersionInfo?> getLatestVersion() async {
    try {
      AppLogger.info(
        '최신 버전 정보 조회: ${currentPlatform.value}',
        'AppVersionService',
      );

      final response = await _dio.get(
        '/api/app-version/latest',
        queryParameters: {'platform': currentPlatform.value},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        return AppVersionInfo.fromJson(data);
      } else {
        throw Exception('최신 버전 정보 조회 실패: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger.error(
        '최신 버전 정보 조회 중 네트워크 오류: ${e.message}',
        tag: 'AppVersionService',
        error: e,
      );
      return null;
    } catch (e) {
      AppLogger.error(
        '최신 버전 정보 조회 중 오류: $e',
        tag: 'AppVersionService',
        error: e,
      );
      return null;
    }
  }

  /// 버전 비교
  ///
  /// 두 버전을 비교하여 v1이 v2보다 낮은지 확인합니다.
  /// Returns: true if v1 < v2
  bool isVersionLower(String v1, String v2) {
    final v1Parts = v1.split('.').map(int.parse).toList();
    final v2Parts = v2.split('.').map(int.parse).toList();

    for (int i = 0; i < v1Parts.length && i < v2Parts.length; i++) {
      if (v1Parts[i] < v2Parts[i]) return true;
      if (v1Parts[i] > v2Parts[i]) return false;
    }

    return v1Parts.length < v2Parts.length;
  }
}
