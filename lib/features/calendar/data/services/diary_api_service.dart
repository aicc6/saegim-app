import 'dart:io';

import 'package:dio/dio.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/features/calendar/data/models/diary_image_model.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 다이어리 API 서비스
class DiaryApiService {
  DiaryApiService._();

  static final DiaryApiService _instance = DiaryApiService._();
  static DiaryApiService get instance => _instance;

  /// 중앙화된 Dio 인스턴스 사용 (CookieManager가 자동으로 쿠키 기반 인증 처리)
  Dio get dio => DioClient.instance.dio;

  /// 필터링 조건으로 다이어리 목록 조회 (페이지네이션 지원)
  ///
  /// [page]: 페이지 번호 (1부터 시작)
  /// [pageSize]: 페이지 크기 (최대 100)
  /// [searchTerm]: 제목/내용 통합 검색어
  /// [emotion]: 감정 필터 (happy, sad, angry, peaceful, unrest)
  /// [startDate]: 시작 날짜
  /// [endDate]: 종료 날짜
  /// [sortOrder]: 정렬 순서 (asc, desc)
  Future<List<DiaryEntry>?> getDiariesWithFilters({
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
    String? emotion,
    DateTime? startDate,
    DateTime? endDate,
    String sortOrder = 'desc',
  }) async {
    try {
      AppLogger.info(
        'Fetching diaries with filters - Page: $page, PageSize: $pageSize',
        'DiaryApiService',
      );

      // 쿼리 파라미터 구성
      final queryParameters = <String, dynamic>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
        'sort_order': sortOrder,
      };

      // 선택적 파라미터 추가
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParameters['searchTerm'] = searchTerm;
      }

      if (emotion != null && emotion.isNotEmpty) {
        queryParameters['emotion'] = emotion;
      }

      if (startDate != null) {
        final startDateString =
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
        queryParameters['start_date'] = startDateString;
      }

      if (endDate != null) {
        final endDateString =
            '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
        queryParameters['end_date'] = endDateString;
      }

      AppLogger.info('Query parameters: $queryParameters', 'DiaryApiService');

      // API 호출
      final response = await dio.get(
        '/api/diary',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final responseData = response.data;

        // 응답 데이터 구조 파싱
        List<dynamic> diariesData = [];

        if (responseData is Map<String, dynamic>) {
          // BaseResponse 구조인 경우
          if (responseData.containsKey('data')) {
            final data = responseData['data'];
            if (data is List) {
              diariesData = data;
            }
          }
        } else if (responseData is List) {
          // 직접 리스트로 반환되는 경우
          diariesData = responseData;
        }

        AppLogger.info(
          'Raw response structure: ${responseData.runtimeType}',
          'DiaryApiService',
        );

        if (diariesData.isNotEmpty) {
          try {
            // 첫 번째 아이템의 상세 구조 로깅
            if (diariesData.isNotEmpty) {
              final firstItem = diariesData.first as Map<String, dynamic>;
              AppLogger.info(
                'First diary item structure: $firstItem',
                'DiaryApiService',
              );
              AppLogger.info(
                'Keywords type: ${firstItem['keywords'].runtimeType}',
                'DiaryApiService',
              );
              if (firstItem.containsKey('keywords')) {
                final keywords = firstItem['keywords'] as List;
                AppLogger.info(
                  'Keywords value: ${firstItem['keywords']}',
                  'DiaryApiService',
                );
                if (keywords.isNotEmpty) {
                  AppLogger.info(
                    'First keyword type: ${keywords.first.runtimeType}',
                    'DiaryApiService',
                  );
                  AppLogger.info(
                    'First keyword value: ${keywords.first}',
                    'DiaryApiService',
                  );
                }
              }
            }

            final diaries = diariesData
                .map(
                  (item) => DiaryEntry.fromJson(item as Map<String, dynamic>),
                )
                .toList();

            AppLogger.info(
              'Successfully loaded ${diaries.length} diaries for page $page',
              'DiaryApiService',
            );

            return diaries;
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
            'No diaries found for the given filters',
            'DiaryApiService',
          );
          return [];
        }
      } else {
        AppLogger.warning(
          'Failed to load diaries: ${response.statusCode}',
          'DiaryApiService',
        );
        return [];
      }
    } on DioException catch (dioError) {
      final statusCode = dioError.response?.statusCode;

      if (statusCode == 401) {
        AppLogger.warning(
          'Authentication required for diary access',
          'DiaryApiService',
        );
      } else if (statusCode == 404) {
        AppLogger.info('No diaries found', 'DiaryApiService');
        return [];
      } else {
        AppLogger.error(
          'Failed to load diaries with filters',
          tag: 'DiaryApiService',
          error: dioError,
        );
      }
      return [];
    } catch (e) {
      AppLogger.error(
        'Unexpected error loading diaries with filters',
        tag: 'DiaryApiService',
        error: e,
      );
      return [];
    }
  }

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
              return diaryDate != null &&
                  diaryDate.isAfter(
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
      final emotion = diary.aiEmotion ?? diary.emotion ?? '평온';
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

  /// 다이어리 생성
  ///
  /// [content]: 다이어리 본문 (필수)
  /// [aiGeneratedText]: AI가 생성한 글
  /// [userEmotion]: 사용자가 선택한 감정
  /// [aiEmotion]: AI가 분석한 감정
  /// [aiEmotionConfidence]: AI 감정 신뢰도 (0.0~1.0)
  /// [keywords]: 키워드 배열
  /// [diaryDate]: 다이어리 작성 날짜 (YYYY-MM-DD)
  Future<DiaryEntry?> createDiary({
    required String content,
    String? title,
    String? aiGeneratedText,
    String? userEmotion,
    String? aiEmotion,
    double? aiEmotionConfidence,
    List<String>? keywords,
    String? diaryDate,
    List<Map<String, dynamic>>? uploadedImages,
  }) async {
    try {
      AppLogger.info('Creating new diary', 'DiaryApiService');

      // 백엔드 API 스펙에 맞춘 데이터 구조
      final diaryData = <String, dynamic>{
        'content': content, // 필수
      };

      // 선택적 필드 추가
      if (title != null && title.isNotEmpty) {
        diaryData['title'] = title;
      }

      if (aiGeneratedText != null && aiGeneratedText.isNotEmpty) {
        diaryData['ai_generated_text'] = aiGeneratedText;
      }

      if (userEmotion != null && userEmotion.isNotEmpty) {
        // 영어 감정은 그대로 전달 (이미 정규화됨)
        diaryData['user_emotion'] = userEmotion;
      }

      if (aiEmotion != null && aiEmotion.isNotEmpty) {
        // 영어 감정은 그대로 전달 (이미 정규화됨)
        diaryData['ai_emotion'] = aiEmotion;
      }

      if (aiEmotionConfidence != null) {
        diaryData['ai_emotion_confidence'] = aiEmotionConfidence;
      }

      if (keywords != null && keywords.isNotEmpty) {
        diaryData['keywords'] = keywords;
      }

      if (diaryDate != null && diaryDate.isNotEmpty) {
        diaryData['diary_date'] = diaryDate;
      }

      if (uploadedImages != null && uploadedImages.isNotEmpty) {
        diaryData['uploaded_images'] = uploadedImages;
        AppLogger.info(
          'Added uploaded_images to diary creation request: ${uploadedImages.length} images',
          'DiaryApiService',
        );
        for (int i = 0; i < uploadedImages.length; i++) {
          AppLogger.info(
            'Image $i: ${uploadedImages[i]['original_url']}',
            'DiaryApiService',
          );
        }
      } else {
        AppLogger.warning(
          'No uploaded_images provided for diary creation',
          'DiaryApiService',
        );
      }

      AppLogger.info(
        'Creating diary with user_emotion: ${diaryData['user_emotion']}, ai_emotion: ${diaryData['ai_emotion']}',
        'DiaryApiService',
      );

      final response = await dio.post('/api/diary', data: diaryData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        AppLogger.info('Diary created successfully', 'DiaryApiService');

        // 서버 응답 로깅 추가
        AppLogger.info('Server response: ${response.data}', 'DiaryApiService');

        // 응답 데이터 파싱
        Map<String, dynamic> responseData = {};

        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;

          if (responseMap.containsKey('success') &&
              responseMap['success'] == true) {
            responseData = responseMap['data'] ?? {};
          } else if (responseMap.containsKey('data')) {
            final data = responseMap['data'];
            if (data is Map<String, dynamic>) {
              responseData = data;
            }
          } else {
            responseData = responseMap;
          }
        }

        if (responseData.isNotEmpty) {
          return DiaryEntry.fromJson(responseData);
        }

        return null;
      } else {
        AppLogger.warning(
          'Failed to create diary: ${response.statusCode}',
          'DiaryApiService',
        );
        return null;
      }
    } on DioException catch (dioError) {
      final statusCode = dioError.response?.statusCode;

      if (statusCode == 422) {
        AppLogger.warning(
          'Validation error: ${dioError.response?.data}',
          'DiaryApiService',
        );
      } else {
        AppLogger.error(
          'Failed to create diary',
          tag: 'DiaryApiService',
          error: dioError,
        );
      }
      return null;
    } catch (e) {
      AppLogger.error(
        'Unexpected error creating diary',
        tag: 'DiaryApiService',
        error: e,
      );
      return null;
    }
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
    DateTime? diaryDate,
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
      if (diaryDate != null) {
        // 날짜를 YYYY-MM-DD 형식으로 변환
        updateData['diary_date'] =
            '${diaryDate.year}-${diaryDate.month.toString().padLeft(2, '0')}-${diaryDate.day.toString().padLeft(2, '0')}';
      }

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
    // 디버깅을 위한 로그 추가
    AppLogger.info(
      'Keyword statistics calculation - Total diaries: ${diaries.length}, Total keywords: $totalKeywords',
      'DiaryApiService',
    );
    AppLogger.info('Keyword counts: $keywordCounts', 'DiaryApiService');

    final statistics = <KeywordStatistics>[];

    keywordCounts.forEach((keyword, count) {
      final percentage = totalKeywords > 0
          ? (count / totalKeywords * 100)
          : 0.0;

      // 개별 키워드 계산 로그
      AppLogger.info(
        'Keyword "$keyword": count=$count, totalKeywords=$totalKeywords, percentage=${percentage.toStringAsFixed(1)}%',
        'DiaryApiService',
      );

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

        // 이미지 파일 존재 여부 사전 확인 (URL은 건너뛰기)
        final validImagePaths = <String>[];
        for (final imagePath in imagePaths) {
          // URL인 경우 (이미 업로드된 이미지)는 건너뛰기
          if (imagePath.startsWith('http://') ||
              imagePath.startsWith('https://')) {
            AppLogger.info(
              '⏭️ Skipping already uploaded image URL: ${imagePath.split('/').last}',
              'DiaryApiService',
            );
            continue;
          }

          final file = File(imagePath);
          if (await file.exists()) {
            validImagePaths.add(imagePath);
            AppLogger.info(
              '✅ Image file exists: ${file.path.split('/').last}',
              'DiaryApiService',
            );
          } else {
            AppLogger.warning(
              '❌ Image file does not exist: $imagePath',
              'DiaryApiService',
            );
          }
        }

        if (validImagePaths.isEmpty) {
          AppLogger.warning(
            '⚠️ No valid image files found, skipping upload',
            'DiaryApiService',
          );
          continue;
        }

        final result = await _attemptImageUpload(
          endpoint,
          diaryId,
          validImagePaths,
        );
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
    // API 문서에 따른 정확한 방법: 'image' 필드명으로 파일 전송
    try {
      // diary_id는 URL에 이미 포함되어 있으므로 FormData에 추가하지 않음
      AppLogger.info(
        '📝 diary_id already in URL, skipping FormData field',
        'DiaryApiService',
      );

      final List<DiaryImage> uploadedImages = [];

      for (final imagePath in imagePaths) {
        final file = File(imagePath);
        if (!(await file.exists())) {
          AppLogger.warning(
            '⚠️ Image file does not exist: $imagePath',
            'DiaryApiService',
          );
          continue;
        }

        final fileName = file.path.split('/').last;
        final formData = FormData();
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );

        AppLogger.info(
          '📤 Uploading single image to $endpoint: $fileName',
          'DiaryApiService',
        );

        final response = await dio.post(
          endpoint,
          data: formData,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          AppLogger.info(
            '✅ Successfully uploaded image: $fileName',
            'DiaryApiService',
          );
          final parsed = _parseImageUploadResponse(response.data);
          if (parsed != null && parsed.isNotEmpty) {
            uploadedImages.addAll(parsed);
          }
        } else {
          AppLogger.warning(
            '❌ Upload failed (${response.statusCode}) for image: $fileName',
            'DiaryApiService',
          );
          AppLogger.warning(
            '📋 Error response: ${response.data}',
            'DiaryApiService',
          );
        }
      }

      return uploadedImages.isNotEmpty ? uploadedImages : null;
    } catch (e) {
      AppLogger.error(
        '❌ Error during image upload: $e',
        tag: 'DiaryApiService',
      );
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

  /// 다이어리 content 조회 (사용자 입력 원본)
  ///
  /// [diaryId]: 조회할 다이어리 ID
  Future<String?> getDiaryContent(String diaryId) async {
    try {
      AppLogger.info('📝 Fetching diary content: $diaryId', 'DiaryApiService');

      final response = await dio.get('/api/diary/$diaryId/content');

      if (response.statusCode == 200) {
        final data = response.data;

        // 응답 데이터 파싱
        String? content;
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            final dataMap = data['data'] as Map<String, dynamic>;
            content = dataMap['content'] as String?;
          } else if (data.containsKey('content')) {
            content = data['content'] as String?;
          }
        }

        AppLogger.info(
          '✅ Successfully loaded content for diary: $diaryId',
          'DiaryApiService',
        );
        return content;
      } else {
        AppLogger.warning(
          'Failed to load diary content: ${response.statusCode}',
          'DiaryApiService',
        );
        return null;
      }
    } on DioException catch (dioError) {
      final statusCode = dioError.response?.statusCode;

      if (statusCode == 404) {
        AppLogger.info(
          'Content not found for diary: $diaryId',
          'DiaryApiService',
        );
        return null;
      }

      AppLogger.error(
        '❌ DioException loading diary content: $diaryId - Status: $statusCode',
        tag: 'DiaryApiService',
        error: dioError,
      );
      return null;
    } catch (e) {
      AppLogger.error(
        'Unexpected error loading diary content: $diaryId',
        tag: 'DiaryApiService',
        error: e,
      );
      return null;
    }
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

      final response = await dio.delete('/api/diary/$diaryId/images/$imageId');

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

      // 404 오류는 이미 삭제된 상태로 간주하여 성공 처리
      if (statusCode == 404) {
        AppLogger.info(
          '✅ Image already deleted (404): $imageId',
          'DiaryApiService',
        );
        return true;
      }

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
