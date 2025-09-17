import 'package:dio/dio.dart';
import 'package:saegim/core/network/dio_client.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:saegim/core/services/auth_storage_service.dart';

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
    // 매번 새로운 Dio 인스턴스를 생성하여 최신 토큰 적용
    final dioInstance = DioClient.create();

    // 토큰 로드 재시도 (타이밍 문제 해결)
    String? token;
    for (int i = 0; i < 3; i++) {
      token = await AuthStorageService.instance.getAuthToken();
      if (token != null && token.isNotEmpty) {
        break;
      }
      AppLogger.warning('Token not found, retry ${i + 1}/3', 'DiaryApiService');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (token != null && token.isNotEmpty) {
      if (token == 'session_authenticated_user') {
        // 세션 기반 인증의 경우 쿠키나 다른 방식 사용
        AppLogger.info('Using session-based authentication', 'DiaryApiService');
        // 실제로는 쿠키가 자동으로 포함되거나 다른 인증 방식 사용
      } else {
        dioInstance.options.headers['Authorization'] = 'Bearer $token';
      }
      AppLogger.info(
        'Auth token added to request headers: ${token.substring(0, 10)}...',
        'DiaryApiService',
      );
    } else {
      AppLogger.error(
        'No auth token found after 3 retries',
        tag: 'DiaryApiService',
      );
    }

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

          final authDio = await authenticatedDio;
          // 월의 첫 날과 마지막 날 계산
          final startDate = DateTime(year, month, 1);
          final endDate = DateTime(year, month + 1, 0);
          final startDateString =
              '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}';
          final endDateString =
              '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';

          final response = await authDio.get(
            endpoint,
            queryParameters: {
              'start_date': startDateString,
              'end_date': endDateString,
              'page_size': 100, // 한 달치 데이터 모두 가져오기
            },
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

      // 모든 엔드포인트 실패 - 목업 데이터로 fallback
      AppLogger.warning(
        'All diary endpoints failed for $year-$month, using mock data',
        'DiaryApiService',
      );
      return _generateMockDiaries(year, month);
    } catch (e) {
      AppLogger.error(
        'Error loading monthly diaries for $year-$month',
        tag: 'DiaryApiService',
        error: e,
      );
      return _generateMockDiaries(year, month);
    }
  }

  /// 목업 다이어리 데이터 생성 (백엔드 연동 실패 시 사용)
  List<DiaryEntry> _generateMockDiaries(int year, int month) {
    AppLogger.info(
      'Generating mock diary data for $year-$month',
      'DiaryApiService',
    );

    final mockDiaries = <DiaryEntry>[];
    final emotions = ['행복', '슬픔', '화남', '평온', '불안'];
    final keywords = [
      '가족',
      '친구',
      '직장',
      '취미',
      '운동',
      '음식',
      '여행',
      '공부',
      '휴식',
      '스트레스',
      '사랑',
      '건강',
      '성장',
      '도전',
      '감사',
    ];

    // 현재 월의 일부 날짜에 다이어리 생성
    final mockData = [
      {'day': 3, 'emotion': '행복'},
      {'day': 7, 'emotion': '평온'},
      {'day': 12, 'emotion': '슬픔'},
      {'day': 15, 'emotion': '행복'},
      {'day': 18, 'emotion': '불안'},
      {'day': 22, 'emotion': '평온'},
      {'day': 25, 'emotion': '행복'},
      {'day': 28, 'emotion': '화남'},
      {'day': 30, 'emotion': '행복'},
    ];

    for (int i = 0; i < mockData.length; i++) {
      final data = mockData[i];
      final day = data['day'] as int;
      final emotion = data['emotion'] as String;

      // 1~9개의 랜덤 키워드 생성
      final random = DateTime.now().millisecondsSinceEpoch + i;
      final keywordCount = (random % 9) + 1; // 1~9개
      final diaryKeywords = <String>[];

      // 중복 없이 키워드 선택
      final shuffledKeywords = List<String>.from(keywords);
      shuffledKeywords.shuffle();

      for (int j = 0; j < keywordCount && j < shuffledKeywords.length; j++) {
        diaryKeywords.add(shuffledKeywords[j]);
      }

      // 해당 월의 유효한 날짜인지 확인
      final daysInMonth = DateTime(year, month + 1, 0).day;
      if (day <= daysInMonth) {
        mockDiaries.add(
          DiaryEntry(
            id: 'mock_${year}_${month}_$i',
            title: '$emotion한 하루',
            content:
                '오늘은 ${diaryKeywords.join(', ')}에 대해 생각하며 $emotion한 감정을 느꼈습니다. 백엔드 연동이 완료되면 실제 데이터로 대체됩니다.',
            emotion: emotion,
            aiEmotion: emotion,
            keywords: diaryKeywords,
            diaryDate: DateTime(year, month, day),
            createdAt: DateTime(year, month, day, 20, 30),
            isPublic: false,
          ),
        );
      }
    }

    AppLogger.info(
      'Generated ${mockDiaries.length} mock diaries',
      'DiaryApiService',
    );
    return mockDiaries;
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
