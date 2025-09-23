import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/features/calendar/data/services/diary_api_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

part 'calendar_notifier.g.dart';

/// 캘린더 상태 모델
class CalendarState {
  final DateTime currentDate;
  final DateTime? selectedDate;
  final bool isLoading;
  final List<DiaryEntry> monthlyDiaries;
  final List<EmotionStatistics> emotionStatistics;
  final List<KeywordStatistics> keywordStatistics;
  final String? errorMessage;

  const CalendarState({
    required this.currentDate,
    this.selectedDate,
    this.isLoading = false,
    this.monthlyDiaries = const [],
    this.emotionStatistics = const [],
    this.keywordStatistics = const [],
    this.errorMessage,
  });

  CalendarState copyWith({
    DateTime? currentDate,
    DateTime? selectedDate,
    bool? isLoading,
    List<DiaryEntry>? monthlyDiaries,
    List<EmotionStatistics>? emotionStatistics,
    List<KeywordStatistics>? keywordStatistics,
    String? errorMessage,
  }) {
    return CalendarState(
      currentDate: currentDate ?? this.currentDate,
      selectedDate: selectedDate,
      isLoading: isLoading ?? this.isLoading,
      monthlyDiaries: monthlyDiaries ?? this.monthlyDiaries,
      emotionStatistics: emotionStatistics ?? this.emotionStatistics,
      keywordStatistics: keywordStatistics ?? this.keywordStatistics,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'CalendarState(currentDate: $currentDate, selectedDate: $selectedDate, isLoading: $isLoading)';
  }
}

/// 캘린더 상태 관리 NotifierProvider
@riverpod
class CalendarNotifier extends _$CalendarNotifier {
  DiaryApiService get _apiService => DiaryApiService.instance;

  @override
  CalendarState build() {
    final now = DateTime.now();
    final initialState = CalendarState(currentDate: now);

    // AuthNotifier 상태를 감지하여 인증 상태 변화 시 데이터 새로고침
    ref.listen(authNotifierProvider, (previous, next) {
      // 인증 상태가 변경되었을 때 (로그인/로그아웃)
      if (previous?.isAuthenticated != next.isAuthenticated) {
        AppLogger.info(
          'Auth state changed: ${previous?.isAuthenticated} -> ${next.isAuthenticated}',
          'CalendarNotifier',
        );

        if (next.isAuthenticated) {
          // 로그인 성공 시 현재 월 데이터 새로고침
          Future.microtask(() {
            final currentDate = state.currentDate;
            _loadMonthlyData(currentDate.year, currentDate.month);
          });
        } else {
          // 로그아웃 시 데이터 클리어
          state = state.copyWith(
            monthlyDiaries: [],
            emotionStatistics: [],
            keywordStatistics: [],
          );
        }
      }
    });

    // 초기 데이터 로드 (비동기로 실행)
    Future.microtask(() => _loadMonthlyData(now.year, now.month));

    return initialState;
  }

  /// 월 변경
  void changeMonth(DateTime newDate) {
    state = state.copyWith(currentDate: newDate);
    _loadMonthlyData(newDate.year, newDate.month);
  }

  /// 날짜 선택
  void selectDate(DateTime? date) {
    state = state.copyWith(selectedDate: date);
  }

  /// 오늘로 이동
  void goToToday() {
    final today = DateTime.now();
    state = state.copyWith(currentDate: today, selectedDate: today);
    _loadMonthlyData(today.year, today.month);
  }

  /// 이전 달로 이동
  void goToPreviousMonth() {
    final previousMonth = DateTime(
      state.currentDate.year,
      state.currentDate.month - 1,
    );
    changeMonth(previousMonth);
  }

  /// 다음 달로 이동
  void goToNextMonth() {
    final nextMonth = DateTime(
      state.currentDate.year,
      state.currentDate.month + 1,
    );
    changeMonth(nextMonth);
  }

  /// 월간 데이터 로드 (다이어리, 감정 통계, 키워드 통계)
  Future<void> _loadMonthlyData(int year, int month) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 병렬로 데이터 로드
      final futures = await Future.wait([
        _loadMonthlyDiaries(year, month),
        _loadMonthlyStatistics(year, month),
      ]);

      final diaries = futures[0] as List<DiaryEntry>?;
      final statistics = futures[1] as MonthlyStatisticsResponse?;

      state = state.copyWith(
        isLoading: false,
        monthlyDiaries: diaries ?? [],
        emotionStatistics: statistics?.emotions ?? [],
        keywordStatistics: statistics?.keywords ?? [],
      );

      AppLogger.info(
        'Monthly data loaded for $year-$month: ${diaries?.length ?? 0} diaries',
        'CalendarNotifier',
      );
    } catch (e) {
      AppLogger.error(
        'Failed to load monthly data for $year-$month',
        tag: 'CalendarNotifier',
        error: e,
      );

      state = state.copyWith(
        isLoading: false,
        errorMessage: '데이터를 불러오는데 실패했습니다.',
      );
    }
  }

  /// 월간 다이어리 목록 로드
  Future<List<DiaryEntry>?> _loadMonthlyDiaries(int year, int month) async {
    return await _apiService.getMonthlyDiaries(year: year, month: month);
  }

  /// 월간 통계 로드
  Future<MonthlyStatisticsResponse?> _loadMonthlyStatistics(
    int year,
    int month,
  ) async {
    return await _apiService.getMonthlyStatistics(year: year, month: month);
  }

  /// 특정 날짜의 다이어리 조회
  Future<List<DiaryEntry>> getDailyDiaries(DateTime date) async {
    try {
      final response = await _apiService.getDailyDiaries(date: date);
      return response?.diaries ?? [];
    } catch (e) {
      AppLogger.error(
        'Failed to load daily diaries for ${date.toString()}',
        tag: 'CalendarNotifier',
        error: e,
      );
      return [];
    }
  }

  /// 선택된 날짜의 주요 감정과 키워드 조회
  DiaryEntry? getSelectedDateDiary() {
    if (state.selectedDate == null) return null;

    return state.monthlyDiaries.cast<DiaryEntry?>().firstWhere((diary) {
      if (diary == null) return false;
      final diaryDate = diary.diaryDate;
      final selectedDate = state.selectedDate!;
      return diaryDate.year == selectedDate.year &&
          diaryDate.month == selectedDate.month &&
          diaryDate.day == selectedDate.day;
    }, orElse: () => null);
  }

  /// 특정 날짜에 다이어리가 있는지 확인
  bool hasDiaryOnDate(DateTime date) {
    return state.monthlyDiaries.any((diary) {
      final diaryDate = diary.diaryDate;
      return diaryDate.year == date.year &&
          diaryDate.month == date.month &&
          diaryDate.day == date.day;
    });
  }

  /// 에러 메시지 클리어
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 수동 새로고침
  Future<void> refresh() async {
    final currentDate = state.currentDate;
    await _loadMonthlyData(currentDate.year, currentDate.month);
  }
}
