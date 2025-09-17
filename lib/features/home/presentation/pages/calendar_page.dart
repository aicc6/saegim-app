import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';
import 'package:saegim/features/calendar/presentation/riverpod/calendar_notifier.dart';
import 'package:saegim/features/calendar/data/models/diary_model.dart';

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
        return const Color(0xFFB8956A); // 갈색
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
  }

  // 특정 날짜에 다이어리가 있는지 확인
  bool _hasDiaryOnDate(DateTime date, List<DiaryEntry> diaries) {
    return diaries.any((diary) {
      final diaryDate = diary.createdAt;
      return diaryDate.year == date.year &&
          diaryDate.month == date.month &&
          diaryDate.day == date.day;
    });
  }

  // 특정 날짜의 다이어리 이모티콘 가져오기
  String _getDiaryEmoji(DateTime date, List<DiaryEntry> diaries) {
    final diary = diaries.cast<DiaryEntry?>().firstWhere((diary) {
      if (diary == null) return false;
      final diaryDate = diary.createdAt;
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
      final diaryDate = diary.createdAt;
      return diaryDate.year == date.year &&
          diaryDate.month == date.month &&
          diaryDate.day == date.day;
    }, orElse: () => null);
    return diary?.keywords.isNotEmpty == true ? diary!.keywords.first : '감정';
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(calendarNotifierProvider);
    final calendarDays = _generateCalendarDays(calendarState.currentDate);
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
              child: Column(
                children: [
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
                                              left: 5,
                                              top: 0,
                                              bottom: 0,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                mainAxisSize: MainAxisSize.min,
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
                                                  Text(
                                                    '# ${_getDiaryKeyword(date, calendarState.monthlyDiaries)}',
                                                    style: TextStyle(
                                                      fontSize: 6,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: isToday
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF333333,
                                                            ),
                                                    ),
                                                    overflow: TextOverflow.clip,
                                                    maxLines: 1,
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
                        const SizedBox(height: 24),
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
                ],
              ),
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
