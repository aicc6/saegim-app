import 'package:dio/dio.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 다이어리 API 서비스
class DiaryApiService {
  DiaryApiService._();

  static final DiaryApiService _instance = DiaryApiService._();
  static DiaryApiService get instance => _instance;

  Dio? _dio;

  /// 초기화
  void initialize() {
    _dio = DioClient.create();
  }

  /// Dio 인스턴스 가져오기 (lazy initialization)
  Dio get dio {
    if (_dio == null) {
      initialize();
    }
    return _dio!;
  }

  /// 인증 헤더가 포함된 Dio 인스턴스 가져오기
  Future<Dio> get authenticatedDio async {
    final dioInstance = dio;

    // TODO: 실제 인증 토큰을 가져와서 헤더에 추가
    // final token = await _getAuthToken();
    // if (token != null) {
    //   dioInstance.options.headers['Authorization'] = 'Bearer $token';
    // }

    return dioInstance;
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
      // 실제 백엔드 API 엔드포인트 사용
      final endpoints = [
        '/api/diary/calendar', // 캘린더용 다이어리 API
        '/api/diary', // 일반 다이어리 목록 API
      ];

      for (final endpoint in endpoints) {
        try {
          AppLogger.info(
            'Trying endpoint: $endpoint with year=$year, month=$month',
            'DiaryApiService',
          );

          final response = await dio.get(
            endpoint,
            queryParameters: {'year': year, 'month': month},
          );

          if (response.statusCode == 200) {
            AppLogger.info(
              'Successfully connected to $endpoint',
              'DiaryApiService',
            );

            // 응답 데이터 구조 로깅
            AppLogger.info(
              'Response data: ${response.data}',
              'DiaryApiService',
            );

            // 응답 구조 파싱
            List<dynamic> dataList = [];
            if (response.data is Map<String, dynamic>) {
              final responseMap = response.data as Map<String, dynamic>;
              if (responseMap.containsKey('success') &&
                  responseMap['success'] == true) {
                dataList = responseMap['data'] ?? [];
              } else {
                dataList =
                    responseMap['diaries'] ??
                    responseMap['data'] ??
                    responseMap['items'] ??
                    responseMap['entries'] ??
                    [];
              }
            } else if (response.data is List) {
              dataList = response.data;
            }

            if (dataList.isNotEmpty) {
              try {
                final diaries = dataList
                    .map(
                      (json) =>
                          DiaryEntry.fromJson(json as Map<String, dynamic>),
                    )
                    .toList();

                AppLogger.info(
                  'Monthly diaries loaded: ${diaries.length} entries',
                  'DiaryApiService',
                );
                return diaries;
              } catch (parseError) {
                AppLogger.warning(
                  'Failed to parse diaries from $endpoint: $parseError',
                  'DiaryApiService',
                );
                // 파싱 실패 시 다음 엔드포인트 시도
                continue;
              }
            } else {
              AppLogger.info(
                'No diary data found for $year-$month',
                'DiaryApiService',
              );
              return []; // 빈 배열 반환 (정상적인 응답이지만 데이터 없음)
            }
          }
        } catch (e) {
          AppLogger.warning('Endpoint $endpoint failed: $e', 'DiaryApiService');
          continue;
        }
      }

      // 모든 엔드포인트 실패
      AppLogger.error(
        'All diary endpoints failed for $year-$month',
        tag: 'DiaryApiService',
      );
      return [];
    } catch (e) {
      AppLogger.error(
        'Error loading monthly diaries for $year-$month',
        tag: 'DiaryApiService',
        error: e,
      );
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
      final emotion = diary.emotion;
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
}
