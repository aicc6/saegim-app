import 'package:dio/dio.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/features/calendar/data/models/diary_image_model.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'dart:io';

/// 다이어리 API 서비스
class DiaryApiService {
  DiaryApiService._();

  static final DiaryApiService _instance = DiaryApiService._();
  static DiaryApiService get instance => _instance;

  /// 중앙화된 Dio 인스턴스 사용 (CookieManager가 자동으로 쿠키 기반 인증 처리)
  Dio get dio => DioClient.instance.dio;

  /// 월간 통계 데이터 조회
  ///
  /// [year]: 연도 (예: 2024)
  /// [month]: 월 (1-12)
  Future<MonthlyStatisticsResponse?> getMonthlyStatistics({
    required int year,
    required int month,
  }) async {
    try {
      // 실제 백엔드 API 엔드포인트 사용 (통계 기능은 아직 구현되지 않을 수 있음)
      // 일단 다이어리 데이터를 가져와서 클라이언트 측에서 통계 계산
      AppLogger.info(
        'Fetching monthly diaries for statistics calculation: $year-$month',
        'DiaryApiService',
      );

      final diaries = await getMonthlyDiaries(year: year, month: month);
      if (diaries == null || diaries.isEmpty) {
        AppLogger.info('No diaries found for $year-$month', 'DiaryApiService');
        return MonthlyStatisticsResponse(
          emotions: [],
          keywords: [],
          totalEntries: 0,
          month: month,
          year: year,
        );
      }

      // 클라이언트 측에서 통계 계산
      final emotionStats = _calculateEmotionStatistics(diaries);
      final keywordStats = _calculateKeywordStatistics(diaries);

      return MonthlyStatisticsResponse(
        emotions: emotionStats,
        keywords: keywordStats,
        totalEntries: diaries.length,
        month: month,
        year: year,
      );
    } catch (e) {
      AppLogger.error(
        'Error loading monthly statistics for $year-$month',
        tag: 'DiaryApiService',
        error: e,
      );
      return null;
    }
  }

  /// 특정 날짜의 다이어리 목록 조회
  ///
  /// [date]: 조회할 날짜
  Future<DailyDiariesResponse?> getDailyDiaries({
    required DateTime date,
  }) async {
    try {
      final dateString =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final response = await dio.get(
        '/api/diaries/daily',
        queryParameters: {'date': dateString},
      );

      if (response.statusCode == 200) {
        AppLogger.info(
          'Daily diaries loaded for $dateString',
          'DiaryApiService',
        );
        return DailyDiariesResponse.fromJson(response.data);
      } else {
        AppLogger.warning(
          'Failed to load daily diaries: ${response.statusCode}',
          'DiaryApiService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        'Error loading daily diaries for ${date.toString()}',
        tag: 'DiaryApiService',
        error: e,
      );
      return null;
    }
  }

  /// 월간 다이어리 목록 조회 (캘린더 표시용)
  ///
  /// [year]: 연도
  /// [month]: 월 (1-12)
  Future<List<DiaryEntry>?> getMonthlyDiaries({
    required int year,
    required int month,
  }) async {
    try {
      AppLogger.info(
        'Fetching monthly diaries for $year-$month',
        'DiaryApiService',
      );

      // 실제 백엔드 API 호출 - 올바른 파라미터 사용
      final response = await dio.get(
        '/api/diary',
        queryParameters: {
          'page': 1,
          'page_size': 100, // 한 달치 데이터 모두 가져오기
          // 날짜 필터링은 클라이언트 측에서 처리
        },
      );

      if (response.statusCode == 200) {
        // 응답 데이터 구조 파싱
        List<dynamic> dataList = [];
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;

          // 다양한 응답 구조에 대응
          if (responseMap.containsKey('success') &&
              responseMap['success'] == true) {
            dataList = responseMap['data'] ?? [];
          } else if (responseMap.containsKey('data')) {
            final data = responseMap['data'];
            if (data is List) {
              dataList = data;
            } else if (data is Map && data.containsKey('diaries')) {
              dataList = data['diaries'] ?? [];
            }
          } else {
            // 직접 다이어리 배열이 있는지 확인
            dataList =
                responseMap['diaries'] ??
                responseMap['entries'] ??
                responseMap['items'] ??
                [];
          }
        } else if (response.data is List) {
          dataList = response.data;
        }

        if (dataList.isNotEmpty) {
          try {
            final allDiaries = dataList
                .map(
                  (json) => DiaryEntry.fromJson(json as Map<String, dynamic>),
                )
                .toList();

            // 클라이언트 측에서 해당 월의 데이터만 필터링
            final startDate = DateTime(year, month, 1);
            final endDate = DateTime(year, month + 1, 0);

            final monthlyDiaries = allDiaries.where((diary) {
              final diaryDate = diary.diaryDate;
              return diaryDate.isAfter(
                    startDate.subtract(const Duration(days: 1)),
                  ) &&
                  diaryDate.isBefore(endDate.add(const Duration(days: 1)));
            }).toList();

            AppLogger.info(
              'Loaded ${monthlyDiaries.length} diaries for $year-$month',
              'DiaryApiService',
            );
            return monthlyDiaries;
          } catch (parseError) {
            AppLogger.error(
              'Failed to parse diary data',
              tag: 'DiaryApiService',
              error: parseError,
            );
            return [];
          }
        } else {
          AppLogger.info(
            'No diary data found for $year-$month',
            'DiaryApiService',
          );
          return []; // 빈 배열 반환 (정상적인 응답이지만 데이터 없음)
        }
      } else {
        AppLogger.warning(
          'Backend returned status ${response.statusCode} with data: ${response.data}',
          'DiaryApiService',
        );
        return []; // 목업 데이터 대신 빈 배열 반환
      }
    } on DioException catch (dioError) {
      if (dioError.response?.statusCode == 401) {
        AppLogger.warning(
          'Authentication required for diary access',
          'DiaryApiService',
        );
        return [];
      } else {
        AppLogger.error(
          'Failed to load diaries for $year-$month',
          tag: 'DiaryApiService',
          error: dioError,
        );
        return [];
      }
    } catch (e) {
      AppLogger.error(
        'Unexpected error loading monthly diaries for $year-$month',
        tag: 'DiaryApiService',
        error: e,
      );
      // 목업 데이터 대신 빈 배열 반환하여 실제 문제를 확인
      return [];
    }
  }

  /// 감정 통계 조회 (기간별)
  ///
  /// [startDate]: 시작 날짜
  /// [endDate]: 종료 날짜
  Future<List<EmotionStatistics>?> getEmotionStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startDateString =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateString =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final response = await dio.get(
        '/api/diaries/statistics/emotions',
        queryParameters: {
          'start_date': startDateString,
          'end_date': endDateString,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['emotions'] ?? [];
        final emotions = data
            .map(
              (json) =>
                  EmotionStatistics.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        AppLogger.info(
          'Emotion statistics loaded for $startDateString to $endDateString',
          'DiaryApiService',
        );
        return emotions;
      } else {
        AppLogger.warning(
          'Failed to load emotion statistics: ${response.statusCode}',
          'DiaryApiService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        'Error loading emotion statistics',
        tag: 'DiaryApiService',
        error: e,
      );
      return null;
    }
  }

  /// 키워드 통계 조회 (기간별)
  ///
  /// [startDate]: 시작 날짜
  /// [endDate]: 종료 날짜
  /// [limit]: 반환할 키워드 개수 (기본값: 10)
  Future<List<KeywordStatistics>?> getKeywordStatistics({
    required DateTime startDate,
    required DateTime endDate,
    int limit = 10,
  }) async {
    try {
      final startDateString =
          '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
      final endDateString =
          '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

      final response = await dio.get(
        '/api/diaries/statistics/keywords',
        queryParameters: {
          'start_date': startDateString,
          'end_date': endDateString,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['keywords'] ?? [];
        final keywords = data
            .map(
              (json) =>
                  KeywordStatistics.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        AppLogger.info(
          'Keyword statistics loaded for $startDateString to $endDateString: ${keywords.length} keywords',
          'DiaryApiService',
        );
        return keywords;
      } else {
        AppLogger.warning(
          'Failed to load keyword statistics: ${response.statusCode}',
          'DiaryApiService',
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        'Error loading keyword statistics',
        tag: 'DiaryApiService',
        error: e,
      );
      return null;
    }
  }

  /// 클라이언트 측에서 감정 통계 계산
  List<EmotionStatistics> _calculateEmotionStatistics(
    List<DiaryEntry> diaries,
  ) {
    final emotionCounts = <String, int>{};
    final emotionEmojis = <String, String>{};

    for (final diary in diaries) {
      final emotion = diary.emotion ?? diary.aiEmotion ?? '평온';
      emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      emotionEmojis[emotion] = diary.emotionEmoji;
    }

    final totalEntries = diaries.length;
    final statistics = <EmotionStatistics>[];

    emotionCounts.forEach((emotion, count) {
      final percentage = totalEntries > 0 ? (count / totalEntries * 100) : 0.0;
      statistics.add(
        EmotionStatistics(
          emotion: emotion,
          emoji: emotionEmojis[emotion] ?? '😐',
          count: count,
          percentage: percentage,
        ),
      );
    });

    // 개수 순으로 정렬
    statistics.sort((a, b) => b.count.compareTo(a.count));
    return statistics;
  }

  /// 특정 다이어리 조회
  ///
  /// [diaryId]: 조회할 다이어리 ID
  Future<DiaryEntry?> getDiaryById(String diaryId) async {
    try {
      AppLogger.info('Fetching diary by ID: $diaryId', 'DiaryApiService');

      final response = await dio.get('/api/diary/$diaryId');

      if (response.statusCode == 200) {
        // 응답 데이터 구조 파싱
        Map<String, dynamic> diaryData = {};

        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;

          // 다양한 응답 구조에 대응
          if (responseMap.containsKey('success') &&
              responseMap['success'] == true) {
            diaryData = responseMap['data'] ?? {};
          } else if (responseMap.containsKey('data')) {
            final data = responseMap['data'];
            if (data is Map<String, dynamic>) {
              diaryData = data;
            }
          } else {
            diaryData = responseMap;
          }
        }

        if (diaryData.isNotEmpty) {
          try {
            final diary = DiaryEntry.fromJson(diaryData);
            AppLogger.info(
              'Successfully loaded diary: $diaryId',
              'DiaryApiService',
            );
            return diary;
          } catch (parseError) {
            AppLogger.error(
              'Failed to parse diary data for ID: $diaryId',
              tag: 'DiaryApiService',
              error: parseError,
            );
            return null;
          }
        } else {
          AppLogger.warning(
            'No diary data found for ID: $diaryId',
            'DiaryApiService',
          );
          return null;
        }
      } else {
        AppLogger.warning(
          'Backend returned status ${response.statusCode} for diary ID: $diaryId',
          'DiaryApiService',
        );
        return null;
      }
    } on DioException catch (dioError) {
      if (dioError.response?.statusCode == 401) {
        AppLogger.warning(
          'Authentication required for diary access',
          'DiaryApiService',
        );
        return null;
      } else if (dioError.response?.statusCode == 404) {
        AppLogger.warning('Diary not found: $diaryId', 'DiaryApiService');
        return null;
      } else {
        AppLogger.error(
          'Failed to load diary: $diaryId',
          tag: 'DiaryApiService',
          error: dioError,
        );
        return null;
      }
    } catch (e) {
      AppLogger.error(
        'Unexpected error loading diary: $diaryId',
        tag: 'DiaryApiService',
        error: e,
      );
      return null;
    }
  }

  /// 다이어리 수정
  ///
  /// [diaryId]: 수정할 다이어리 ID
  /// [title]: 수정할 제목
  /// [content]: 다이어리 내용 (기존 내용 유지하려면 전달)
  /// [emotion]: 수정할 사용자 감정
  /// [keywords]: 수정할 키워드 목록
  /// [aiGeneratedText]: 수정할 AI 생성 글
  Future<bool> updateDiary({
    required String diaryId,
    String? title,
    String? content,
    String? emotion,
    List<String>? keywords,
    String? aiGeneratedText,
  }) async {
    try {
      AppLogger.info('📝 Updating diary: $diaryId', 'DiaryApiService');

      // API 문서에서 확인된 요청 데이터 형식
      final updateData = <String, dynamic>{};

      if (title != null) updateData['title'] = title;
      // content는 서버에서 읽기 전용으로 처리되어 500 에러 발생 - 제외
      // if (content != null) updateData['content'] = content;
      // user_emotion은 null이어도 전송 (사용자가 새로 선택한 감정)
      if (emotion != null) updateData['user_emotion'] = emotion;
      if (keywords != null) updateData['keywords'] = keywords;
      if (aiGeneratedText != null)
        updateData['ai_generated_text'] = aiGeneratedText;

      AppLogger.info('📊 Update request data: $updateData', 'DiaryApiService');

      // API 문서에서 확인된 정확한 엔드포인트 사용: PUT /api/diary/{diary_id}
      AppLogger.info(
        '🎯 Using confirmed API: PUT /api/diary/$diaryId',
        'DiaryApiService',
      );

      final response = await dio.put(
        '/api/diary/$diaryId',
        data: updateData,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.info(
          '✅ Successfully updated diary: $diaryId, status: ${response.statusCode}',
          'DiaryApiService',
        );
        return true;
      }

      AppLogger.warning(
        'Update request returned unexpected status: ${response.statusCode}',
        'DiaryApiService',
      );
      return false;
    } on DioException catch (dioError) {
      final statusCode = dioError.response?.statusCode;
      final errorData = dioError.response?.data;

      AppLogger.error(
        '❌ DioException updating diary: $diaryId - Status: $statusCode, Data: $errorData',
        tag: 'DiaryApiService',
        error: dioError,
      );

      if (statusCode == 401) {
        AppLogger.warning(
          '🔒 Authentication required for diary update',
          'DiaryApiService',
        );
      } else if (statusCode == 404) {
        AppLogger.warning('🔍 Diary not found: $diaryId', 'DiaryApiService');
      } else if (statusCode == 405) {
        AppLogger.warning(
          '🚫 Method not allowed for diary update',
          'DiaryApiService',
        );
      } else if (statusCode == 422) {
        AppLogger.warning(
          '📋 Validation error for diary update data',
          'DiaryApiService',
        );
      }
      return false;
    } catch (e) {
      AppLogger.error(
        '💥 Unexpected error updating diary: $diaryId',
        tag: 'DiaryApiService',
        error: e,
      );
      return false;
    }
  }

  /// 다이어리 삭제
  ///
  /// [diaryId]: 삭제할 다이어리 ID
  Future<bool> deleteDiary(String diaryId) async {
    try {
      AppLogger.info('🗑️ Deleting diary: $diaryId', 'DiaryApiService');

      // API 문서에서 확인된 정확한 엔드포인트 사용: DELETE /api/diary/{diary_id}
      AppLogger.info(
        '🎯 Using confirmed API: DELETE /api/diary/$diaryId',
        'DiaryApiService',
      );

      final response = await dio.delete(
        '/api/diary/$diaryId',
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.info(
          '✅ Successfully deleted diary: $diaryId, status: ${response.statusCode}',
          'DiaryApiService',
        );
        return true;
      }

      AppLogger.warning(
        'Delete request returned unexpected status: ${response.statusCode}',
        'DiaryApiService',
      );
      return false;
    } on DioException catch (dioError) {
      final statusCode = dioError.response?.statusCode;
      final errorData = dioError.response?.data;

      AppLogger.error(
        '❌ DioException deleting diary: $diaryId - Status: $statusCode, Data: $errorData',
        tag: 'DiaryApiService',
        error: dioError,
      );

      if (statusCode == 401) {
        AppLogger.warning(
          '🔒 Authentication required for diary deletion',
          'DiaryApiService',
        );
      } else if (statusCode == 404) {
        AppLogger.warning('🔍 Diary not found: $diaryId', 'DiaryApiService');
      } else if (statusCode == 405) {
        AppLogger.warning(
          '🚫 Method not allowed for diary deletion',
          'DiaryApiService',
        );
      }
      return false;
    } catch (e) {
      AppLogger.error(
        '💥 Unexpected error deleting diary: $diaryId',
        tag: 'DiaryApiService',
        error: e,
      );
      return false;
    }
  }

  /// 클라이언트 측에서 키워드 통계 계산
  List<KeywordStatistics> _calculateKeywordStatistics(
    List<DiaryEntry> diaries,
  ) {
    final keywordCounts = <String, int>{};

    for (final diary in diaries) {
      for (final keyword in diary.keywords) {
        keywordCounts[keyword] = (keywordCounts[keyword] ?? 0) + 1;
      }
    }

    final totalKeywords = keywordCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );
    final statistics = <KeywordStatistics>[];

    keywordCounts.forEach((keyword, count) {
      final percentage = totalKeywords > 0
          ? (count / totalKeywords * 100)
          : 0.0;
      statistics.add(
        KeywordStatistics(
          keyword: keyword,
          count: count,
          percentage: percentage,
        ),
      );
    });

    // 개수 순으로 정렬하고 상위 10개만 반환
    statistics.sort((a, b) => b.count.compareTo(a.count));
    return statistics.take(10).toList();
  }

  /// 다이어리 이미지 목록 조회
  ///
  /// [diaryId]: 다이어리 ID
  Future<List<DiaryImage>> getDiaryImages(String diaryId) async {
    try {
      AppLogger.info(
        '🖼️ Fetching images for diary: $diaryId',
        'DiaryApiService',
      );

      final response = await dio.get('/api/diary/$diaryId/images');

      if (response.statusCode == 200) {
        final data = response.data;

        // 디버깅: 실제 응답 데이터 확인
        AppLogger.info('🔍 Raw API response: $data', 'DiaryApiService');

        if (data is List) {
          // 직접 배열로 반환되는 경우
          AppLogger.info(
            '📋 Processing as List with ${data.length} items',
            'DiaryApiService',
          );

          final images = data
              .map((item) {
                AppLogger.info('🔍 Processing item: $item', 'DiaryApiService');
                return DiaryImage.fromJson(item as Map<String, dynamic>);
              })
              .where((image) {
                // 유효한 이미지만 필터링 (filePath가 null이 아니고 비어있지 않은 경우)
                final isValid =
                    image.filePath != null &&
                    image.filePath!.isNotEmpty &&
                    image.fullImageUrl.isNotEmpty;
                if (!isValid) {
                  AppLogger.warning(
                    '⚠️ Skipping invalid image: filePath=${image.filePath}',
                    'DiaryApiService',
                  );
                }
                return isValid;
              })
              .toList();

          AppLogger.info(
            '✅ Successfully loaded ${images.length} images for diary: $diaryId',
            'DiaryApiService',
          );
          return images;
        } else if (data is Map<String, dynamic>) {
          // 객체로 감싸져서 반환되는 경우
          if (data.containsKey('images')) {
            final imagesList = data['images'] as List;
            final images = imagesList
                .map(
                  (item) => DiaryImage.fromJson(item as Map<String, dynamic>),
                )
                .where(
                  (image) =>
                      image.filePath != null &&
                      image.filePath!.isNotEmpty &&
                      image.fullImageUrl.isNotEmpty,
                )
                .toList();

            AppLogger.info(
              '✅ Successfully loaded ${images.length} images for diary: $diaryId',
              'DiaryApiService',
            );
            return images;
          } else if (data.containsKey('data')) {
            final imagesList = data['data'] as List;
            final images = imagesList
                .map(
                  (item) => DiaryImage.fromJson(item as Map<String, dynamic>),
                )
                .where(
                  (image) =>
                      image.filePath != null &&
                      image.filePath!.isNotEmpty &&
                      image.fullImageUrl.isNotEmpty,
                )
                .toList();

            AppLogger.info(
              '✅ Successfully loaded ${images.length} images for diary: $diaryId',
              'DiaryApiService',
            );
            return images;
          }
        }

        AppLogger.warning(
          'Unexpected response format for diary images',
          'DiaryApiService',
        );
        return [];
      } else {
        AppLogger.warning(
          'Failed to load diary images: ${response.statusCode}',
          'DiaryApiService',
        );
        return [];
      }
    } on DioException catch (dioError) {
      final statusCode = dioError.response?.statusCode;

      if (statusCode == 404) {
        AppLogger.info(
          'No images found for diary: $diaryId',
          'DiaryApiService',
        );
        return [];
      }

      AppLogger.error(
        '❌ DioException loading diary images: $diaryId - Status: $statusCode',
        tag: 'DiaryApiService',
        error: dioError,
      );
      return [];
    } catch (e) {
      AppLogger.error(
        'Unexpected error loading diary images: $diaryId',
        tag: 'DiaryApiService',
        error: e,
      );
      return [];
    }
  }

  /// 단일 이미지 조회 (이미지 ID로)
  ///
  /// [imageId]: 이미지 ID
  Future<DiaryImage?> getDiaryImageById(String imageId) async {
    try {
      AppLogger.info('🖼️ Fetching image: $imageId', 'DiaryApiService');

      final response = await dio.get('/api/image/$imageId');

      if (response.statusCode == 200) {
        final data = response.data;
        final image = DiaryImage.fromJson(data as Map<String, dynamic>);

        AppLogger.info(
          '✅ Successfully loaded image: $imageId',
          'DiaryApiService',
        );
        return image;
      } else {
        AppLogger.warning(
          'Failed to load image: $imageId - Status: ${response.statusCode}',
          'DiaryApiService',
        );
        return null;
      }
    } on DioException catch (dioError) {
      final statusCode = dioError.response?.statusCode;

      if (statusCode == 404) {
        AppLogger.info('Image not found: $imageId', 'DiaryApiService');
        return null;
      }

      AppLogger.error(
        '❌ DioException loading image: $imageId - Status: $statusCode',
        tag: 'DiaryApiService',
        error: dioError,
      );
      return null;
    } catch (e) {
      AppLogger.error(
        'Unexpected error loading image: $imageId',
        tag: 'DiaryApiService',
        error: e,
      );
      return null;
    }
  }

  /// 다이어리에 이미지 업로드 (여러 엔드포인트 시도)
  ///
  /// [diaryId]: 다이어리 ID
  /// [imagePaths]: 업로드할 이미지 파일 경로들
  Future<List<DiaryImage>?> uploadDiaryImages({
    required String diaryId,
    required List<String> imagePaths,
  }) async {
    // 사용자가 제안한 엔드포인트를 최우선으로 시도
    final endpointsToTry = [
      '/api/diary/$diaryId/upload-image', // 🎯 API 문서에서 확인한 정확한 엔드포인트 (유일)
    ];

    for (final endpoint in endpointsToTry) {
      try {
        AppLogger.info(
          '📤 Trying to upload ${imagePaths.length} images to: $endpoint',
          'DiaryApiService',
        );

        final result = await _attemptImageUpload(endpoint, diaryId, imagePaths);
        if (result != null) {
          AppLogger.info(
            '✅ Successfully uploaded images using endpoint: $endpoint',
            'DiaryApiService',
          );
          return result;
        }
      } catch (e) {
        AppLogger.warning(
          'Failed with endpoint $endpoint, trying next...',
          'DiaryApiService',
        );
        continue;
      }
    }

    // 모든 엔드포인트 실패 시
    AppLogger.error(
      'All upload endpoints failed for diary: $diaryId',
      tag: 'DiaryApiService',
    );
    return null;
  }

  /// 특정 엔드포인트로 이미지 업로드 시도 (API 문서에 따른 정확한 방법)
  Future<List<DiaryImage>?> _attemptImageUpload(
    String endpoint,
    String diaryId,
    List<String> imagePaths,
  ) async {
    // API 문서에 따른 정확한 방법: 'image' 필드명으로 단일 파일 전송
    try {
      final formData = FormData();

      // diary_id는 URL에 이미 포함되어 있으므로 FormData에 추가하지 않음
      AppLogger.info(
        '📝 diary_id already in URL, skipping FormData field',
        'DiaryApiService',
      );

      // API 문서에 따르면 단일 파일만 지원하므로 첫 번째 이미지만 업로드
      if (imagePaths.isNotEmpty) {
        final file = File(imagePaths.first);
        if (await file.exists()) {
          final fileName = file.path.split('/').last;
          formData.files.add(
            MapEntry(
              'image', // API 문서에 명시된 정확한 필드명
              await MultipartFile.fromFile(file.path, filename: fileName),
            ),
          );

          final response = await dio.post(
            endpoint,
            data: formData,
            options: Options(headers: {'Content-Type': 'multipart/form-data'}),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            AppLogger.info(
              '✅ Successfully uploaded image using correct API format: $endpoint',
              'DiaryApiService',
            );
            return _parseImageUploadResponse(response.data);
          } else {
            AppLogger.warning(
              'Upload failed with status: ${response.statusCode}',
              'DiaryApiService',
            );
          }
        }
      }
    } catch (e) {
      // 방법 1-B: 'files' 필드명으로 시도
      try {
        final formData = FormData();

        // diary ID가 URL에 없는 경우에만 FormData에 추가
        if (!endpoint.contains(diaryId)) {
          formData.fields.add(MapEntry('diary_id', diaryId));
          AppLogger.info(
            '📝 Added diary_id to FormData: $diaryId',
            'DiaryApiService',
          );
        } else {
          AppLogger.info(
            '📝 diary_id already in URL, skipping FormData field',
            'DiaryApiService',
          );
        }

        for (final imagePath in imagePaths) {
          final file = File(imagePath);
          if (await file.exists()) {
            final fileName = file.path.split('/').last;
            formData.files.add(
              MapEntry(
                'files',
                await MultipartFile.fromFile(file.path, filename: fileName),
              ),
            );
          }
        }

        final response = await dio.post(
          endpoint,
          data: formData,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          return _parseImageUploadResponse(response.data);
        }
      } catch (e2) {
        // 방법 1-B도 실패, 다음 방법으로
        AppLogger.warning(
          'Method 1-B failed for endpoint: $endpoint',
          'DiaryApiService',
        );
      }
    }

    // 방법 2: 단일 파일을 'file' 필드로 전송 (첫 번째 이미지만)
    if (imagePaths.isNotEmpty) {
      try {
        final formData = FormData();

        // diary ID가 URL에 없는 경우에만 FormData에 추가
        if (!endpoint.contains(diaryId)) {
          formData.fields.add(MapEntry('diary_id', diaryId));
          AppLogger.info(
            '📝 Added diary_id to FormData: $diaryId',
            'DiaryApiService',
          );
        } else {
          AppLogger.info(
            '📝 diary_id already in URL, skipping FormData field',
            'DiaryApiService',
          );
        }

        final file = File(imagePaths.first);

        if (await file.exists()) {
          final fileName = file.path.split('/').last;
          formData.files.add(
            MapEntry(
              'file',
              await MultipartFile.fromFile(file.path, filename: fileName),
            ),
          );

          final response = await dio.post(
            endpoint,
            data: formData,
            options: Options(headers: {'Content-Type': 'multipart/form-data'}),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            return _parseImageUploadResponse(response.data);
          }
        }
      } catch (e2) {
        // 방법 3: PUT 메서드 시도
        try {
          final formData = FormData();

          // 항상 diary_id를 FormData에 추가
          formData.fields.add(MapEntry('diary_id', diaryId));
          AppLogger.info(
            '📝 Added diary_id to FormData (single file): $diaryId',
            'DiaryApiService',
          );

          final file = File(imagePaths.first);

          if (await file.exists()) {
            final fileName = file.path.split('/').last;
            formData.files.add(
              MapEntry(
                'image',
                await MultipartFile.fromFile(file.path, filename: fileName),
              ),
            );

            final response = await dio.put(
              endpoint,
              data: formData,
              options: Options(
                headers: {'Content-Type': 'multipart/form-data'},
              ),
            );

            if (response.statusCode == 200 || response.statusCode == 201) {
              return _parseImageUploadResponse(response.data);
            }
          }
        } catch (e3) {
          // 모든 방법 실패
          AppLogger.warning(
            'All upload methods failed for endpoint: $endpoint',
            'DiaryApiService',
          );
        }
      }
    }

    return null;
  }

  /// 이미지 업로드 응답 파싱
  List<DiaryImage>? _parseImageUploadResponse(dynamic responseData) {
    try {
      AppLogger.info(
        '🔍 Parsing image upload response: $responseData',
        'DiaryApiService',
      );

      List<dynamic> imagesData = [];

      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('success') &&
            responseData['success'] == true) {
          final data = responseData['data'];
          if (data is List) {
            imagesData = data;
          } else if (data is Map<String, dynamic>) {
            // 단일 이미지 응답인 경우
            imagesData = [data];
          }
        } else if (responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is List) {
            imagesData = data;
          } else if (data is Map<String, dynamic>) {
            imagesData = [data];
          }
        } else if (responseData.containsKey('images')) {
          imagesData = responseData['images'] ?? [];
        } else {
          // 단일 이미지 응답인 경우
          imagesData = [responseData];
        }
      } else if (responseData is List) {
        imagesData = responseData;
      }

      if (imagesData.isNotEmpty) {
        return imagesData
            .map((item) => DiaryImage.fromJson(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      AppLogger.error(
        'Failed to parse image upload response',
        tag: 'DiaryApiService',
        error: e,
      );
    }
    return null;
  }

  /// 다이어리 이미지 삭제
  ///
  /// [imageId]: 삭제할 이미지 ID
  Future<bool> deleteDiaryImage(String diaryId, String imageId) async {
    try {
      AppLogger.info(
        '🗑️ Deleting image: $imageId from diary: $diaryId',
        'DiaryApiService',
      );

      final response = await this.dio.delete(
        '/api/diary/$diaryId/images/$imageId',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.info(
          '✅ Successfully deleted image: $imageId',
          'DiaryApiService',
        );
        return true;
      } else {
        AppLogger.warning(
          'Failed to delete image: ${response.statusCode}',
          'DiaryApiService',
        );
        return false;
      }
    } on DioException catch (dioError) {
      final statusCode = dioError.response?.statusCode;

      AppLogger.error(
        '❌ DioException deleting image: $imageId - Status: $statusCode',
        tag: 'DiaryApiService',
        error: dioError,
      );
      return false;
    } catch (e) {
      AppLogger.error(
        'Unexpected error deleting image: $imageId',
        tag: 'DiaryApiService',
        error: e,
      );
      return false;
    }
  }
}
