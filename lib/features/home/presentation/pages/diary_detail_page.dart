import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiaryDetailPage extends StatelessWidget {
  final String diaryId;

  const DiaryDetailPage({super.key, required this.diaryId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            // 커스텀 앱바
            _buildCustomAppBar(context),

            // 스크롤 가능한 콘텐츠
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목과 날짜
                    _buildTitleSection(),

                    const SizedBox(height: 24),

                    // 감정 분석 섹션
                    _buildEmotionAnalysisSection(),

                    const SizedBox(height: 20),

                    // 키워드 섹션
                    _buildKeywordSection(),

                    const SizedBox(height: 24),

                    // AI 생성 글 섹션
                    _buildAiContentSection(),

                    const SizedBox(height: 32),

                    // 수정/삭제 버튼
                    _buildActionButtons(context),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 커스텀 앱바
  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _handleBackNavigation(context),
            child: const Icon(
              Icons.arrow_back_ios,
              size: 20,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '뒤로가기',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 뒤로가기 네비게이션 처리
  void _handleBackNavigation(BuildContext context) {
    final uri = GoRouter.of(context).routeInformationProvider.value.uri;
    final from = uri.queryParameters['from'];

    if (from == 'calendar') {
      // 캘린더에서 왔다면 캘린더로 돌아가기
      context.go('/calendar');
    } else {
      // 그 외의 경우는 기본 pop 동작 (다이어리 목록으로)
      context.pop();
    }
  }

  // 제목과 날짜 섹션
  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '9월 16일 일기',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '9월 16일',
          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  // 감정 분석 섹션
  Widget _buildEmotionAnalysisSection() {
    return Row(
      children: [
        // 사용자 감정
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '사용자 감정 : ',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    Text('😰', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 4),
                    Text(
                      '불안',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'AI 분석 감정 : ',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    Text('😰', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 4),
                    Text(
                      '불안',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '(80%)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 키워드 섹션
  Widget _buildKeywordSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '키워드 :',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildKeywordChip('#시험'),
              _buildKeywordChip('#초조함'),
              _buildKeywordChip('#불안'),
              _buildKeywordChip('#월레벌떡'),
              _buildKeywordChip('#안쓰러움'),
            ],
          ),
        ],
      ),
    );
  }

  // 키워드 칩
  Widget _buildKeywordChip(String keyword) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        keyword,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF4A7C59),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // AI 생성 글 섹션
  Widget _buildAiContentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '흔느끼는 시계소리, 초조함의 나락에서\n불안한 내 그림자는 월레벌떡 고개 숙여\n빗속의 고독처럼 안쓰러게 젖어드는,\n숨 쉬는 것조차, 시험의 검은 날개 아래서.',
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 100),
          Center(
            child: Text(
              '•',
              style: TextStyle(fontSize: 24, color: Color(0xFFB2C5B8)),
            ),
          ),
        ],
      ),
    );
  }

  // 수정/삭제 버튼
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 수정 버튼
        Container(
          width: 120,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFB2C5B8),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextButton(
            onPressed: () {
              // TODO: 수정 기능 구현
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('수정 기능은 아직 구현되지 않았습니다.')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 4),
                Text(
                  '수정',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 삭제 버튼
        Container(
          width: 120,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextButton(
            onPressed: () {
              _showDeleteConfirmDialog(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_outline, size: 16),
                SizedBox(width: 4),
                Text(
                  '삭제',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 삭제 확인 다이얼로그
  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('일기 삭제'),
          content: const Text('정말로 이 일기를 삭제하시겠습니까?\n삭제된 일기는 복구할 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 실제 삭제 기능 구현
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('삭제 기능은 아직 구현되지 않았습니다.')),
                );
              },
              child: const Text(
                '삭제',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
            ),
          ],
        );
      },
    );
  }
}
