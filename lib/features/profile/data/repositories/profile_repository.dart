import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/features/profile/data/models/user_profile_model.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 프로필 관련 API 호출을 담당하는 레포지토리
class ProfileRepository {
  ProfileRepository() : _dio = DioClient.instance.dio;

  final Dio _dio;

  /// 현재 로그인한 사용자 프로필을 조회합니다.
  Future<UserProfileModel> fetchProfile() async {
    try {
      final response = await _dio.get('/api/auth/me');

      if (response.statusCode == HttpStatus.ok) {
        final data = response.data as Map<String, dynamic>?;
        if (data == null) {
          throw Exception('서버 응답을 파싱할 수 없습니다.');
        }

        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          return UserProfileModel.fromJson(
            data['data'] as Map<String, dynamic>,
          );
        }

        throw Exception(data['message']?.toString() ?? '프로필 정보를 불러오지 못했습니다.');
      }

      throw Exception('서버 오류: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('프로필 조회 실패', error: e, tag: 'ProfileRepository');
      throw Exception(_resolveErrorMessage(e, '프로필 정보를 불러오지 못했습니다.'));
    } catch (e) {
      AppLogger.error('프로필 조회 중 알 수 없는 오류', error: e, tag: 'ProfileRepository');
      rethrow;
    }
  }

  /// 닉네임 중복 여부를 확인합니다.
  Future<bool> checkNicknameAvailability(String nickname) async {
    try {
      final response = await _dio.get('/api/auth/check-nickname/$nickname');

      if (response.statusCode == HttpStatus.ok) {
        final data = response.data as Map<String, dynamic>?;
        if (data == null) {
          return false;
        }

        return data['data']?['available'] == true;
      }
      return false;
    } on DioException catch (e) {
      AppLogger.error('닉네임 중복 확인 실패', error: e, tag: 'ProfileRepository');
      return false;
    }
  }

  /// 프로필 닉네임 및 이미지 URL을 업데이트합니다.
  Future<ProfileUpdateResult> updateProfile(
    ProfileUpdateRequest request,
  ) async {
    try {
      final response = await _dio.put(
        '/api/auth/profile',
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatus.ok) {
        final data = response.data as Map<String, dynamic>?;
        if (data == null) {
          throw Exception('서버 응답을 파싱할 수 없습니다.');
        }

        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          final profileJson = data['data'] as Map<String, dynamic>;
          return ProfileUpdateResult.fromJson(profileJson);
        }

        throw Exception(data['message']?.toString() ?? '프로필 업데이트에 실패했습니다.');
      }

      throw Exception('서버 오류: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('프로필 업데이트 실패', error: e, tag: 'ProfileRepository');
      throw Exception(_resolveErrorMessage(e, '프로필 업데이트에 실패했습니다.'));
    } catch (e) {
      AppLogger.error(
        '프로필 업데이트 중 알 수 없는 오류',
        error: e,
        tag: 'ProfileRepository',
      );
      rethrow;
    }
  }

  /// 프로필 이미지를 업로드하고 저장된 이미지 URL을 반환합니다.
  Future<String> uploadProfileImage(XFile file) async {
    try {
      final fileName = file.name.isNotEmpty
          ? file.name
          : file.path.split('/').last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await DioClient.instance.uploadImage(
        '/api/auth/profile/upload-image',
        formData,
      );

      if (response.statusCode == HttpStatus.ok) {
        final data = response.data as Map<String, dynamic>?;
        if (data == null) {
          throw Exception('이미지 업로드 응답을 파싱할 수 없습니다.');
        }

        if (data['success'] == true && data['data'] is Map<String, dynamic>) {
          final imageUrl = (data['data'] as Map<String, dynamic>)['image_url'];
          if (imageUrl is String && imageUrl.isNotEmpty) {
            return imageUrl;
          }
        }

        throw Exception(data['message']?.toString() ?? '이미지 업로드에 실패했습니다.');
      }

      throw Exception('이미지 업로드 실패: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('프로필 이미지 업로드 실패', error: e, tag: 'ProfileRepository');
      throw Exception(_resolveErrorMessage(e, '이미지 업로드에 실패했습니다.'));
    } catch (e) {
      AppLogger.error(
        '이미지 업로드 중 알 수 없는 오류',
        error: e,
        tag: 'ProfileRepository',
      );
      rethrow;
    }
  }

  /// 이메일 변경 인증 메일을 발송합니다.
  Future<void> sendEmailChangeVerification(
    EmailVerificationRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/auth/change-email/send-verification',
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatus.ok) {
        final data = response.data as Map<String, dynamic>?;
        if (data != null && data['success'] == true) {
          return;
        }

        throw Exception(data?['message']?.toString() ?? '이메일 변경 요청에 실패했습니다.');
      }

      throw Exception('이메일 변경 요청 실패: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('이메일 변경 인증 요청 실패', error: e, tag: 'ProfileRepository');
      throw Exception(_resolveErrorMessage(e, '이메일 변경 요청에 실패했습니다.'));
    } catch (e) {
      AppLogger.error(
        '이메일 변경 인증 요청 중 알 수 없는 오류',
        error: e,
        tag: 'ProfileRepository',
      );
      rethrow;
    }
  }

  /// 계정 탈퇴를 요청합니다.
  Future<void> requestAccountWithdrawal(WithdrawAccountRequest request) async {
    try {
      final response = await _dio.post(
        '/api/auth/withdraw',
        data: request.toJson(),
      );

      if (response.statusCode == HttpStatus.ok) {
        final data = response.data as Map<String, dynamic>?;
        if (data != null && data['success'] == true) {
          return;
        }

        throw Exception(data?['message']?.toString() ?? '계정 탈퇴에 실패했습니다.');
      }

      throw Exception('계정 탈퇴 요청 실패: ${response.statusCode}');
    } on DioException catch (e) {
      AppLogger.error('계정 탈퇴 요청 실패', error: e, tag: 'ProfileRepository');
      throw Exception(_resolveErrorMessage(e, '계정 탈퇴에 실패했습니다.'));
    } catch (e) {
      AppLogger.error(
        '계정 탈퇴 요청 중 알 수 없는 오류',
        error: e,
        tag: 'ProfileRepository',
      );
      rethrow;
    }
  }

  String _resolveErrorMessage(DioException error, String defaultMessage) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 400) {
      final detail = error.response?.data is Map
          ? error.response?.data['detail']?.toString()
          : null;
      return detail ?? '입력한 정보를 다시 확인해주세요.';
    }

    if (statusCode == 401) {
      return '인증이 필요합니다. 다시 로그인해주세요.';
    }

    if (statusCode == 403) {
      return '요청 권한이 없습니다.';
    }

    if (statusCode == 404) {
      return '요청한 리소스를 찾을 수 없습니다.';
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return '네트워크 연결이 원활하지 않습니다. 잠시 후 다시 시도해주세요.';
    }

    if (error.type == DioExceptionType.connectionError) {
      return '인터넷 연결을 확인해주세요.';
    }

    return defaultMessage;
  }
}

/// ProfileRepository Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});
