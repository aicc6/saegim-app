import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';
import 'package:saegim/features/calendar/presentation/riverpod/calendar_notifier.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
import 'package:saegim/features/calendar/data/models/diary_image_model.dart';
import 'package:saegim/features/calendar/data/services/diary_api_service.dart';
import 'package:saegim/features/calendar/presentation/widgets/test_login_widget.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';
import 'package:saegim/shared/utils/app_logger.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

// 감정 데이터 모델
class EmotionData {
  final String name;
  final String emoji;
  final int count;
  final Color color;

  EmotionData({
    required this.name,
    required this.emoji,
    required this.count,
    required this.color,
  });
}

// 키워드 데이터 모델
class KeywordData {
  final String name;
  final int count;
  final double percentage;

  KeywordData({
    required this.name,
    required this.count,
    required this.percentage,
  });
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  // 스크롤 컨트롤러 추가
  final ScrollController _scrollController = ScrollController();
  // 다이어리 상세 정보 위젯의 GlobalKey
  final GlobalKey _diaryDetailKey = GlobalKey();
  late PageController _pageController;

  // 다이어리별 이미지 캐시
  final Map<String, List<DiaryImage>> _diaryImagesCache = {};
  final Set<String> _loadingImages = {};

  // 숨겨진 다이어리 ID 목록
  final Set<String> _hiddenDiaryIds = {};

  // 삭제 중인 다이어리 ID 목록
  final Set<String> _deletingDiaryIds = {};

  // 감정 색상 매핑 (5가지 기본 감정) - 채도 조정
  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case '행복':
      case 'happy':
        return const Color(0xFFF9C74F); // 부드러운 노란색 (채도 낮춤)
      case '평온':
      case 'peaceful':
        return const Color(0xFF90C695); // 부드러운 초록색 (채도 낮춤)
      case '불안':
      case 'unrest':
        return const Color(0xFFB388C4); // 부드러운 보라색 (채도 낮춤)
      case '분노':
      case 'angry':
        return const Color(0xFFE76F51); // 주황에 빨간색 섞인 색 (채도 낮춤)
      case '슬픔':
      case 'sad':
        return const Color(0xFF6FA8DC); // 부드러운 파란색 (채도 낮춤)
      default:
        return const Color(0xFF90C695); // 기본 색상 (평온한 초록색)
    }
  }

  /// 감정을 한글로 변환
  String _getKoreanEmotion(String? emotion) {
    if (emotion == null || emotion.isEmpty) return '평온';

    switch (emotion.toLowerCase()) {
      case 'happy':
        return '행복';
      case 'peaceful':
        return '평온';
      case 'unrest':
      case 'anxious':
        return '불안';
      case 'angry':
        return '분노';
      case 'sad':
        return '슬픔';
      default:
        return emotion; // 이미 한글이거나 알 수 없는 감정인 경우 그대로 반환
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// 다이어리 이미지 로드
  Future<void> _loadDiaryImages(String diaryId) async {
    // 이미 로딩 중이거나 캐시에 있으면 스킵
    if (_loadingImages.contains(diaryId) ||
        _diaryImagesCache.containsKey(diaryId)) {
      return;
    }

    _loadingImages.add(diaryId);

    try {
      final images = await DiaryApiService.instance.getDiaryImages(diaryId);

      if (mounted) {
        setState(() {
          _diaryImagesCache[diaryId] = images;
          _loadingImages.remove(diaryId);
        });
      }
    } catch (e) {
      AppLogger.error(
        'Failed to load images for diary: $diaryId',
        tag: 'CalendarPage',
        error: e,
      );
      if (mounted) {
        setState(() {
          _diaryImagesCache[diaryId] = [];
          _loadingImages.remove(diaryId);
        });
      }
    }
  }

  // 해당 월의 첫 번째 날짜
  DateTime _getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  // 해당 월의 마지막 날짜
  DateTime _getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  // 달력 그리드에 표시할 날짜들 생성
  List<DateTime?> _generateCalendarDays(DateTime month) {
    final firstDay = _getFirstDayOfMonth(month);
    final lastDay = _getLastDayOfMonth(month);
    final firstDayWeekday = firstDay.weekday % 7; // 일요일을 0으로 만들기

    List<DateTime?> days = [];

    // 이전 달의 날짜들로 빈 공간 채우기
    for (int i = 0; i < firstDayWeekday; i++) {
      final prevMonthDay = firstDay.subtract(
        Duration(days: firstDayWeekday - i),
      );
      days.add(prevMonthDay);
    }

    // 현재 달의 날짜들 추가
    for (int day = 1; day <= lastDay.day; day++) {
      days.add(DateTime(month.year, month.month, day));
    }

    // 다음 달의 날짜들로 42개(6주)까지 채우기
    int remainingDays = 42 - days.length;
    for (int i = 1; i <= remainingDays; i++) {
      final nextMonthDay = DateTime(month.year, month.month + 1, i);
      days.add(nextMonthDay);
    }

    return days;
  }

  // 오늘로 이동
  void _goToToday() {
    final today = DateTime.now();

    // 먼저 오늘 날짜로 이동
    ref.read(calendarNotifierProvider.notifier).goToToday();

    // 약간의 지연 후 오늘 날짜 선택 및 스크롤 (달력 새로고침 완료 대기)
    Future.delayed(const Duration(milliseconds: 500), () {
      _selectDate(today);
    });
  }

  // 이전 달로 이동
  void _goToPreviousMonth() {
    ref.read(calendarNotifierProvider.notifier).goToPreviousMonth();
  }

  // 다음 달로 이동
  void _goToNextMonth() {
    ref.read(calendarNotifierProvider.notifier).goToNextMonth();
  }

  // 날짜가 오늘인지 확인
  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  // 날짜가 현재 월에 속하는지 확인
  bool _isCurrentMonth(DateTime date, DateTime currentDate) {
    return date.month == currentDate.month && date.year == currentDate.year;
  }

  // 날짜가 선택된 날짜인지 확인
  bool _isSelectedDate(DateTime date, DateTime? selectedDate) {
    if (selectedDate == null) return false;
    return date.year == selectedDate.year &&
        date.month == selectedDate.month &&
        date.day == selectedDate.day;
  }

  // 날짜 선택
  void _selectDate(DateTime date) {
    // 새로운 날짜를 선택할 때 숨겨진 다이어리 목록 초기화
    _hiddenDiaryIds.clear();

    ref.read(calendarNotifierProvider.notifier).selectDate(date);

    // 다이어리가 있는 날짜를 선택했을 때 상세 정보로 스크롤
    final calendarState = ref.read(calendarNotifierProvider);
    final hasDiary = calendarState.monthlyDiaries.any(
      (diary) =>
          diary.diaryDate?.year == date.year &&
          diary.diaryDate?.month == date.month &&
          diary.diaryDate?.day == date.day,
    );

    if (hasDiary) {
      // 약간의 지연 후 스크롤 (위젯 렌더링 완료 대기)
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_diaryDetailKey.currentContext != null) {
          Scrollable.ensureVisible(
            _diaryDetailKey.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.1, // 화면 상단에서 10% 위치에 표시
          );
        }
      });
    }
  }

  // 특정 날짜에 다이어리가 있는지 확인
  bool _hasDiaryOnDate(DateTime date, List<DiaryEntry> diaries) {
    return diaries.any((diary) {
      final diaryDate = diary.diaryDate;
      return diaryDate != null &&
          diaryDate.year == date.year &&
          diaryDate.month == date.month &&
          diaryDate.day == date.day;
    });
  }

  // 특정 날짜의 다이어리 목록 가져오기
  List<DiaryEntry> _getDiariesForDate(DateTime date, List<DiaryEntry> diaries) {
    return diaries.where((diary) {
      final diaryDate = diary.diaryDate;
      return diaryDate != null &&
          diaryDate.year == date.year &&
          diaryDate.month == date.month &&
          diaryDate.day == date.day;
    }).toList();
  }

  // 특정 날짜의 다이어리 이모티콘 가져오기 (첫 번째 다이어리 기준)
  String _getDiaryEmoji(DateTime date, List<DiaryEntry> diaries) {
    final dailyDiaries = _getDiariesForDate(date, diaries);
    return dailyDiaries.isNotEmpty ? dailyDiaries.first.emotionEmoji : '😊';
  }

  // 특정 날짜의 다이어리 키워드 가져오기 (첫 번째 다이어리 기준)
  String _getDiaryKeyword(DateTime date, List<DiaryEntry> diaries) {
    final dailyDiaries = _getDiariesForDate(date, diaries);
    if (dailyDiaries.isNotEmpty && dailyDiaries.first.keywords.isNotEmpty) {
      return dailyDiaries.first.keywords.first;
    }
    return '감정';
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final calendarDays = _generateCalendarDays(calendarState.currentDate);

    // 인증 상태가 변경되면 데이터 새로고침
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (previous?.isAuthenticated != next.isAuthenticated &&
          next.isAuthenticated) {
        AppLogger.info(
          'Auth state changed to authenticated, refreshing calendar data',
          'CalendarPage',
        );
        ref.read(calendarNotifierProvider.notifier).refresh();
      }
    });
    final monthNames = [
      '1월',
      '2월',
      '3월',
      '4월',
      '5월',
      '6월',
      '7월',
      '8월',
      '9월',
      '10월',
      '11월',
      '12월',
    ];

    return Scaffold(
      appBar: const CommonAppBar(),
      body: calendarState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A7C59)),
            )
          : calendarState.errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    calendarState.errorMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(calendarNotifierProvider.notifier).refresh();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A7C59),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  // 테스트 로그인 위젯 (개발용)
                  if (!authState.isAuthenticated) const TestLoginWidget(),

                  // 상단 헤더
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '캘린더',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '월간 감정 기록과 키워드 분석을 확인해보세요',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 월 네비게이션과 오늘 날짜 버튼
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 30), // 왼쪽 공간 확보
                        // 월 네비게이션 (중앙)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: _goToPreviousMonth,
                              icon: const Icon(
                                Icons.chevron_left,
                                color: Color(0xFF4A7C59),
                              ),
                              iconSize: 22,
                            ),
                            Text(
                              '${calendarState.currentDate.year}년 ${monthNames[calendarState.currentDate.month - 1]}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF333333),
                              ),
                            ),
                            IconButton(
                              onPressed: _goToNextMonth,
                              icon: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF4A7C59),
                              ),
                              iconSize: 22,
                            ),
                          ],
                        ),
                        // 오늘 날짜로 이동 버튼 (오른쪽)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4F1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFB2C5B8),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _goToToday,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                child: Text(
                                  '${DateTime.now().day}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A7C59),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 달력
                  Container(
                    height: 400, // 고정 높이 설정
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // 요일 헤더
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                          child: Row(
                            children: ['일', '월', '화', '수', '목', '금', '토'].map((
                              day,
                            ) {
                              return Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: day == '일'
                                          ? Colors.red[400]
                                          : day == '토'
                                          ? Colors.blue[400]
                                          : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        // 날짜 그리드
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 7,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 0,
                                  mainAxisSpacing: 0,
                                ),
                            itemCount: calendarDays.length,
                            itemBuilder: (context, index) {
                              final date = calendarDays[index];
                              if (date == null) return const SizedBox();

                              final isToday = _isToday(date);
                              final isCurrentMonth = _isCurrentMonth(
                                date,
                                calendarState.currentDate,
                              );
                              final isSelected = _isSelectedDate(
                                date,
                                calendarState.selectedDate,
                              );
                              final weekday = index % 7;

                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                padding: const EdgeInsets.all(1), // 셀 간 간격
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? const Color.fromRGBO(
                                            113,
                                            162,
                                            129,
                                            1,
                                          ) // 오늘 날짜는 항상 진한 초록
                                        : isSelected
                                        ? const Color(
                                            0xFFB2C5B8,
                                          ) // 선택된 날짜는 연한 초록
                                        : isCurrentMonth
                                        ? const Color(
                                            0xFFF8F9FA,
                                          ) // 현재 달 날짜는 연한 세이지
                                        : Colors.transparent, // 다른 달 날짜는 투명
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        _selectDate(date);
                                      },
                                      child: Stack(
                                        children: [
                                          // 날짜 숫자 (오른쪽 위 고정)
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: Text(
                                              '${date.day}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight:
                                                    (isToday || isSelected)
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isToday
                                                    ? Colors.white
                                                    : isSelected
                                                    ? Colors.white
                                                    : !isCurrentMonth
                                                    ? Colors.grey[400]
                                                    : weekday == 0
                                                    ? Colors.red[400]
                                                    : weekday == 6
                                                    ? Colors.blue[400]
                                                    : const Color(0xFF333333),
                                              ),
                                            ),
                                          ),
                                          // 감정 이모티콘과 키워드 (다이어리가 있는 날짜에만)
                                          if (_hasDiaryOnDate(
                                            date,
                                            calendarState.monthlyDiaries,
                                          ))
                                            Positioned(
                                              left: 4,
                                              top: 4,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  // 이모티콘
                                                  Text(
                                                    _getDiaryEmoji(
                                                      date,
                                                      calendarState
                                                          .monthlyDiaries,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 1),
                                                  // 키워드
                                                  SizedBox(
                                                    width: 32,
                                                    child: Text(
                                                      '# ${_getDiaryKeyword(date, calendarState.monthlyDiaries)}',
                                                      style: TextStyle(
                                                        fontSize: 6,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: isToday
                                                            ? Colors.white
                                                            : isSelected
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFF333333,
                                                              ),
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          // 다이어리 개수 배지 (여러 개일 때만)
                                          if (_getDiariesForDate(
                                                date,
                                                calendarState.monthlyDiaries,
                                              ).length >
                                              1)
                                            Positioned(
                                              right: 2,
                                              bottom: 2,
                                              child: Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF4A7C59,
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${_getDiariesForDate(date, calendarState.monthlyDiaries).length}',
                                                    style: const TextStyle(
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 선택된 날짜의 다이어리 상세 정보 (조건부 표시)
                  if (calendarState.selectedDate != null &&
                      _getDiariesForDate(
                        calendarState.selectedDate!,
                        calendarState.monthlyDiaries,
                      ).isNotEmpty)
                    Container(
                      key: _diaryDetailKey,
                      child: _buildSelectedDiaryDetail(calendarState),
                    ),

                  const SizedBox(height: 16),

                  // 감정 분포 차트
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '감정 분포',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 원형 차트와 범례를 가로로 배치
                        Row(
                          children: [
                            // 왼쪽 여백
                            Expanded(child: Container()),
                            // 원형 차트 (중앙)
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  PieChart(
                                    PieChartData(
                                      sections: _getPieChartSections(
                                        calendarState.emotionStatistics,
                                      ),
                                      centerSpaceRadius: 25,
                                      sectionsSpace: 1.5,
                                      startDegreeOffset: -90,
                                      borderData: FlBorderData(show: false),
                                    ),
                                  ),
                                  // 중앙 텍스트
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${calendarState.emotionStatistics.fold(0, (sum, emotion) => sum + emotion.count)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      const Text(
                                        '총 기록',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF666666),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // 중간 여백 (차트와 범례 사이) - 조금 더 넓게
                            Expanded(flex: 2, child: Container()),
                            // 범례 (오른쪽)
                            _buildEmotionLegend(
                              calendarState.emotionStatistics,
                            ),
                            // 오른쪽 여백
                            Expanded(child: Container()),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 주요 키워드 막대그래프
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '주요 키워드',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            Text(
                              '총 ${calendarState.keywordStatistics.fold(0, (sum, keyword) => sum + keyword.count)}개',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // 키워드 막대그래프 목록
                        Column(
                          children: calendarState.keywordStatistics
                              .asMap()
                              .entries
                              .map((entry) {
                                final index = entry.key;
                                final keyword = entry.value;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      // 순위 번호
                                      Container(
                                        width: 16,
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // 키워드명
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          keyword.keyword,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF333333),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // 막대그래프
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            // 배경 막대
                                            Container(
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF0F4F1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            // 실제 데이터 막대
                                            FractionallySizedBox(
                                              widthFactor:
                                                  keyword.percentage / 100,
                                              child: Container(
                                                height: 20,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xFF8BC4A0),
                                                          Color(0xFF71A281),
                                                        ],
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // 개수와 퍼센트
                                      SizedBox(
                                        width: 40,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${keyword.count}개',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF333333),
                                              ),
                                            ),
                                            Text(
                                              '${keyword.percentage.toStringAsFixed(1)}%',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              })
                              .toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 이달의 요약 섹션
                  _buildMonthlySummary(calendarState),
                ],
              ),
            ),
    );
  }

  // 다이어리 삭제 확인 모달 표시
  void _showDeleteConfirmDialog(String diaryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            '다이어리 삭제',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          content: const Text(
            '정말로 이 다이어리를 삭제하시겠습니까?\n삭제된 다이어리는 복구할 수 없습니다.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                '취소',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDiary(diaryId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE76F51),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '삭제',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // 다이어리 삭제 처리
  Future<void> _deleteDiary(String diaryId) async {
    if (!mounted) return;

    try {
      // 삭제 중 상태로 표시
      setState(() {
        _deletingDiaryIds.add(diaryId);
      });

      // API 호출로 다이어리 삭제
      final success = await DiaryApiService.instance.deleteDiary(diaryId);

      if (!mounted) return;

      // 삭제 중 상태 해제
      setState(() {
        _deletingDiaryIds.remove(diaryId);
      });

      if (success) {
        // 삭제 성공 시 목록에서 제거
        setState(() {
          _hiddenDiaryIds.add(diaryId);
        });

        // 캘린더 데이터 새로고침
        ref.read(calendarNotifierProvider.notifier).refresh();

        // 성공 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('다이어리가 삭제되었습니다'),
            backgroundColor: Color(0xFF4A7C59),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // 삭제 실패 시 에러 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('다이어리 삭제에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: Color(0xFFE76F51),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // 삭제 중 상태 해제
      setState(() {
        _deletingDiaryIds.remove(diaryId);
      });

      AppLogger.error(
        'Failed to delete diary: $diaryId',
        tag: 'CalendarPage',
        error: e,
      );

      // 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('다이어리 삭제 중 오류가 발생했습니다.'),
          backgroundColor: Color(0xFFE76F51),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // 선택된 날짜의 다이어리 상세 정보 빌드
  Widget _buildSelectedDiaryDetail(CalendarState calendarState) {
    final selectedDate = calendarState.selectedDate!;

    // 선택된 날짜의 모든 다이어리 가져오기 (숨겨진 다이어리 제외)
    final allDailyDiaries = _getDiariesForDate(
      selectedDate,
      calendarState.monthlyDiaries,
    );

    final dailyDiaries = allDailyDiaries
        .where((diary) => !_hiddenDiaryIds.contains(diary.id))
        .toList();

    if (dailyDiaries.isEmpty) {
      // 모든 다이어리가 숨겨졌으면 전체 요약 보기도 닫기
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(calendarNotifierProvider.notifier).selectDate(null);
        }
      });
      return const SizedBox.shrink();
    }

    // 여러 다이어리 목록을 개별 컨테이너로 표시
    return Column(
      children: [
        // 헤더 (날짜와 전체 닫기 버튼)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')} 기록',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              IconButton(
                onPressed: () {
                  _hiddenDiaryIds.clear();
                  ref.read(calendarNotifierProvider.notifier).selectDate(null);
                },
                icon: Icon(Icons.close, color: Colors.grey[400], size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 각 다이어리를 개별 컨테이너로 표시
        ...dailyDiaries.asMap().entries.map((entry) {
          final index = entry.key;
          final diary = entry.value;

          return Column(
            children: [
              if (index > 0) const SizedBox(height: 12),
              _buildSingleDiaryContainer(diary, selectedDate, index + 1),
            ],
          );
        }),
      ],
    );
  }

  // 개별 다이어리 컨테이너 빌드 (개별 X 버튼 포함)
  Widget _buildSingleDiaryContainer(
    DiaryEntry diary,
    DateTime selectedDate,
    int diaryNumber,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 개별 다이어리 헤더 (다이어리 번호와 X 버튼)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 생성일자 표시 (로컬 시간으로 변환)
                Text(
                  () {
                    final localTime = diary.createdAt.toLocal();
                    return '${localTime.month}/${localTime.day} ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
                  }(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // X 버튼 (삭제 확인 모달 표시 또는 로딩 표시)
                _deletingDiaryIds.contains(diary.id)
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF4A7C59),
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: () {
                          _showDeleteConfirmDialog(diary.id);
                        },
                        icon: Icon(
                          Icons.close,
                          color: Colors.grey[400],
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
              ],
            ),
          ),

          // 다이어리 내용
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSingleDiaryCard(diary, selectedDate, diaryNumber),
          ),
        ],
      ),
    );
  }

  // 개별 다이어리 카드 빌드
  Widget _buildSingleDiaryCard(
    DiaryEntry diary,
    DateTime selectedDate,
    int diaryNumber,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목과 감정 이모지
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    diary.title ??
                        '${selectedDate.month}월 ${selectedDate.day}일의 일기',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diary.aiGeneratedText ?? diary.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Text(diary.emotionEmoji, style: const TextStyle(fontSize: 32)),
          ],
        ),

        const SizedBox(height: 16),

        // 감정
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getEmotionColor(
                  diary.aiEmotion ?? diary.emotion ?? '평온',
                ).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getEmotionColor(
                    diary.aiEmotion ?? diary.emotion ?? '평온',
                  ).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _getKoreanEmotion(diary.aiEmotion ?? diary.emotion),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getEmotionColor(
                    diary.aiEmotion ?? diary.emotion ?? '평온',
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 키워드들
        if (diary.keywords.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: diary.keywords.map((keyword) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
                ),
                child: Text(
                  '#$keyword',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 12),

        // 이미지 섹션
        _buildDiaryImages(diary),

        const SizedBox(height: 16),

        // 상세보기 버튼
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // 다이어리 상세 페이지로 이동 (캘린더에서 왔다는 정보 전달)
              AppLogger.info(
                'Navigate to diary detail: ${diary.id}',
                'CalendarPage',
              );
              context.go('/diary/${diary.id}?from=calendar');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A7C59),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '상세 보기',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 이달의 요약 섹션 빌드
  Widget _buildMonthlySummary(CalendarState calendarState) {
    // 가장 많은 감정 찾기
    final topEmotion = calendarState.emotionStatistics.isNotEmpty
        ? calendarState.emotionStatistics.reduce(
            (a, b) => a.count > b.count ? a : b,
          )
        : null;

    // 가장 많은 키워드 찾기
    final topKeyword = calendarState.keywordStatistics.isNotEmpty
        ? calendarState.keywordStatistics.reduce(
            (a, b) => a.count > b.count ? a : b,
          )
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '이달의 요약',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const Spacer(),
              Icon(Icons.analytics_outlined, color: Colors.grey[400], size: 20),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              // 총 기록 수
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE9ECEF),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '총 기록 수',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${calendarState.monthlyDiaries.length}개',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // 가장 많은 감정
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE9ECEF),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '가장 많은 감정',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (topEmotion != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _getKoreanEmotion(topEmotion.emotion),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: _getEmotionColor(topEmotion.emotion),
                              ),
                            ),
                            Text(
                              '${topEmotion.count}회',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          '-',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 주요 키워드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '주요 키워드',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                if (topKeyword != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        topKeyword.keyword,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      Text(
                        '${topKeyword.count}회',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(
                    '-',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 파이차트 섹션 데이터 생성
  List<PieChartSectionData> _getPieChartSections(
    List<EmotionStatistics> emotions,
  ) {
    return emotions.map((emotion) {
      return PieChartSectionData(
        color: _getEmotionColor(emotion.emotion),
        value: emotion.count.toDouble(),
        title: '',
        radius: 45,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  /// 다이어리 이미지 섹션 빌드
  Widget _buildDiaryImages(DiaryEntry diary) {
    // 이미지 로드 시작 (캐시에 없는 경우)
    if (!_diaryImagesCache.containsKey(diary.id) &&
        !_loadingImages.contains(diary.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDiaryImages(diary.id);
      });
    }

    final images = _diaryImagesCache[diary.id] ?? [];
    final isLoading = _loadingImages.contains(diary.id);

    // 이미지가 없고 로딩 중도 아니면 빈 위젯 반환
    if (images.isEmpty && !isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoading)
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A7C59)),
                ),
              ),
            ),
          )
        else if (images.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final image = images[index];
                return _buildImageThumbnail(image, index, images);
              },
            ),
          ),
      ],
    );
  }

  /// 이미지 썸네일 빌드
  Widget _buildImageThumbnail(
    DiaryImage image,
    int index,
    List<DiaryImage> allImages,
  ) {
    final imageUrl = image.fullImageUrl;

    if (imageUrl.isEmpty) {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: const Icon(
          Icons.broken_image_outlined,
          color: Color(0xFF9CA3AF),
          size: 24,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showImageFullScreen(image, index, allImages),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;

              return Container(
                color: Colors.grey[100],
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4A7C59),
                      ),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[100],
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: Color(0xFF9CA3AF),
                  size: 24,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// 이미지 풀스크린 표시
  void _showImageFullScreen(
    DiaryImage image,
    int initialIndex,
    List<DiaryImage> allImages,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // 이미지 페이지뷰
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                final currentImage = allImages[index];
                final imageUrl = currentImage.fullImageUrl;

                if (imageUrl.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: Colors.white54,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '이미지 경로가 없습니다',
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;

                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 64,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '이미지를 불러올 수 없습니다',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            // 닫기 버튼
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
            ),
            // 이미지 정보
            if (allImages.length > 1)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${initialIndex + 1} / ${allImages.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 감정 범례 위젯 빌드
  Widget _buildEmotionLegend(List<EmotionStatistics> emotions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: emotions.map((emotion) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // 색상 점 (왼쪽부터)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getEmotionColor(emotion.emotion),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              // 이모티콘
              Text(emotion.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              // 감정 이름과 갯수, 퍼센트를 세로로 배치
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_getKoreanEmotion(emotion.emotion)} ${emotion.count}개',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                  Text(
                    '${emotion.percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
