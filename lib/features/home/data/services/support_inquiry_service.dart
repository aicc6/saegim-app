import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/features/home/data/models/support_inquiry_model.dart';

/// 고객센터 문의 API 서비스
class SupportInquiryService {
  final Dio _dio;

  SupportInquiryService(this._dio);

  /// 고객센터 문의 등록
  Future<SupportInquiryResponse> createInquiry(
    SupportInquiryRequest request,
  ) async {
    try {
      final response = await _dio.post(
        '/api/support/inquiries',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        // BaseResponse 구조에서 data 필드 추출
        final responseData = response.data;
        if (responseData['success'] == true && responseData['data'] != null) {
          return SupportInquiryResponse.fromJson(responseData['data']);
        } else {
          throw Exception(responseData['message'] ?? '문의 등록에 실패했습니다.');
        }
      } else {
        throw Exception('문의 등록에 실패했습니다. (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        // 유효성 검사 오류
        final errorDetails = e.response?.data;
        if (errorDetails != null && errorDetails['detail'] != null) {
          final details = errorDetails['detail'] as List;
          if (details.isNotEmpty) {
            final firstError = details.first;
            throw Exception('입력 오류: ${firstError['msg'] ?? '알 수 없는 오류'}');
          }
        }
        throw Exception('입력 정보를 확인해주세요.');
      } else if (e.response?.statusCode == 400) {
        throw Exception('입력 정보를 확인해주세요.');
      } else if (e.response?.statusCode == 401) {
        throw Exception('로그인이 필요합니다.');
      } else if (e.response?.statusCode == 500) {
        throw Exception('서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.');
      } else {
        throw Exception('네트워크 오류가 발생했습니다. 인터넷 연결을 확인해주세요.');
      }
    } catch (e) {
      throw Exception('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 내 문의 목록 조회 (추후 구현 가능)
  Future<List<SupportInquiryResponse>> getMyInquiries() async {
    try {
      final response = await _dio.get('/api/support/inquiries');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => SupportInquiryResponse.fromJson(json))
            .toList();
      } else {
        throw Exception('문의 목록 조회에 실패했습니다. (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('로그인이 필요합니다.');
      } else {
        throw Exception('네트워크 오류가 발생했습니다.');
      }
    } catch (e) {
      throw Exception('알 수 없는 오류가 발생했습니다.');
    }
  }
}

/// SupportInquiryService Provider
final supportInquiryServiceProvider = Provider<SupportInquiryService>((ref) {
  final dio = DioClient.instance.dio;
  return SupportInquiryService(dio);
});
