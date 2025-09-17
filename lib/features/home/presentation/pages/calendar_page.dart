import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';
import 'package:saegim/features/calendar/presentation/riverpod/calendar_notifier.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';
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

  // 감정 색상 매핑
  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case '행복':
      case 'happy':
        return const Color(0xFFE6C77D); // 노란색
      case '슬픔':
      case 'sad':
        return const Color(0xFF7B9BD1); // 파란색
      case '화남':
      case 'angry':
        return const Color(0xFFFF7043); // 주황색
      case '평온':
      case 'calm':
        return const Color(0xFF8BC4A0); // 초록색
      case '불안':
      case 'anxious':
        return const Color(0xFF9B7BB8); // 보라색
      default:
        return const Color(0xFFB2C5B8); // 기본 색상
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
    ref.read(calendarNotifierProvider.notifier).goToToday();
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
    ref.read(calendarNotifierProvider.notifier).selectDate(date);

    // 다이어리가 있는 날짜를 선택했을 때 상세 정보로 스크롤
    final calendarState = ref.read(calendarNotifierProvider);
    final hasDiary = calendarState.monthlyDiaries.any(
      (diary) =>
          diary.diaryDate.year == date.year &&
          diary.diaryDate.month == date.month &&
          diary.diaryDate.day == date.day,
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
      return diaryDate.year == date.year &&
          diaryDate.month == date.month &&
          diaryDate.day == date.day;
    });
  }

  // 특정 날짜의 다이어리 이모티콘 가져오기
  String _getDiaryEmoji(DateTime date, List<DiaryEntry> diaries) {
    final diary = diaries.cast<DiaryEntry?>().firstWhere((diary) {
      if (diary == null) return false;
      final diaryDate = diary.diaryDate;
      return diaryDate.year == date.year &&
          diaryDate.month == date.month &&
          diaryDate.day == date.day;
    }, orElse: () => null);
    return diary?.emotionEmoji ?? '😊';
  }

  // 특정 날짜의 다이어리 키워드 가져오기
  String _getDiaryKeyword(DateTime date, List<DiaryEntry> diaries) {
    final diary = diaries.cast<DiaryEntry?>().firstWhere((diary) {
      if (diary == null) return false;
      final diaryDate = diary.diaryDate;
      return diaryDate.year == date.year &&
          diaryDate.month == date.month &&
          diaryDate.day == date.day;
    }, orElse: () => null);
    return diary?.keywords.isNotEmpty == true ? diary!.keywords.first : '감정';
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

                  // 인증 상태 디버그 정보 (개발용)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: authState.isAuthenticated
                          ? Colors.green[50]
                          : Colors.red[50],
                      border: Border.all(
                        color: authState.isAuthenticated
                            ? Colors.green
                            : Colors.red,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          authState.isAuthenticated
                              ? Icons.check_circle
                              : Icons.error,
                          color: authState.isAuthenticated
                              ? Colors.green
                              : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.isAuthenticated
                                ? '인증됨: ${authState.userEmail ?? "사용자"}'
                                : '인증 필요',
                            style: TextStyle(
                              fontSize: 12,
                              color: authState.isAuthenticated
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ),
                        if (authState.isAuthenticated)
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(calendarNotifierProvider.notifier)
                                  .refresh();
                            },
                            child: const Text(
                              '새로고침',
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ),

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
                          '월간 감정 기록과 기념일 분석을 확인하세요',
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
                                color: Colors.black.withValues(alpha: 0.1),
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
                          color: Colors.black.withValues(alpha: 0.05),
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
                                padding: const EdgeInsets.all(
                                  0.5,
                                ), // border 공간 확보
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
                                        : Colors.transparent,
                                    // 모든 셀에 완전한 border 적용 (겹침 방지를 위해 내부 Container 사용)
                                    border: Border.all(
                                      color: (isToday && isSelected)
                                          ? const Color(0xFF2D4A35)
                                          : isToday
                                          ? const Color(0xFF4A7C59)
                                          : isSelected
                                          ? const Color(0xFF4A7C59)
                                          : isCurrentMonth
                                          ? const Color(0xFFB2C5B8)
                                          : const Color(0xFFE0E8E3),
                                      width: 0.5,
                                    ),
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
                      calendarState.monthlyDiaries.any(
                        (diary) =>
                            diary.diaryDate.year ==
                                calendarState.selectedDate!.year &&
                            diary.diaryDate.month ==
                                calendarState.selectedDate!.month &&
                            diary.diaryDate.day ==
                                calendarState.selectedDate!.day,
                      ))
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
                          color: Colors.black.withValues(alpha: 0.05),
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
                        const SizedBox(height: 20),
                        // 원형 차트 (중앙 정렬)
                        Center(
                          child: SizedBox(
                            width: 180,
                            height: 180,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sections: _getPieChartSections(
                                      calendarState.emotionStatistics,
                                    ),
                                    centerSpaceRadius: 40,
                                    sectionsSpace: 2,
                                    startDegreeOffset: -90,
                                    borderData: FlBorderData(show: false),
                                  ),
                                ),
                                // 중앙 텍스트
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${calendarState.emotionStatistics.fold(0, (sum, emotion) => sum + emotion.count)}',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    const Text(
                                      '총 기록',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 범례 (차트 아래)
                        Column(
                          children: calendarState.emotionStatistics.map((
                            emotion,
                          ) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: _getEmotionColor(emotion.emotion),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    emotion.emoji,
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${emotion.emotion} ${emotion.count}개',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        Text(
                                          '${emotion.percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
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
                          color: Colors.black.withValues(alpha: 0.05),
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

  // 선택된 날짜의 다이어리 상세 정보 빌드
  Widget _buildSelectedDiaryDetail(CalendarState calendarState) {
    final selectedDate = calendarState.selectedDate!;

    // 선택된 날짜에 다이어리가 있는지 확인
    final diary = calendarState.monthlyDiaries
        .where(
          (diary) =>
              diary.diaryDate.year == selectedDate.year &&
              diary.diaryDate.month == selectedDate.month &&
              diary.diaryDate.day == selectedDate.day,
        )
        .firstOrNull;

    if (diary == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
          // 헤더 (날짜와 닫기 버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')} 기록',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              IconButton(
                onPressed: () {
                  ref.read(calendarNotifierProvider.notifier).selectDate(null);
                },
                icon: Icon(Icons.close, color: Colors.grey[400], size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          const SizedBox(height: 16),

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
                      diary.content,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getEmotionColor(diary.emotion).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getEmotionColor(diary.emotion).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  diary.emotion,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getEmotionColor(diary.emotion),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 키워드들
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

          const SizedBox(height: 16),

          // 이미지 섹션 (플레이스홀더)
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  size: 32,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  '이미지 없음',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 상세보기 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // TODO: 상세보기 페이지로 이동
                AppLogger.info(
                  'Navigate to diary detail: ${diary.id}',
                  'CalendarPage',
                );
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
                    '클릭하여 상세 보기',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
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
                              topEmotion.emotion,
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
}
