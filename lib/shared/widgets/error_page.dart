import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:saegim/app/routes/route_paths.dart';

/// 에러 페이지
/// 라우팅 에러나 예상치 못한 오류 발생시 표시
class ErrorPage extends StatelessWidget {
  final String error;
  
  const ErrorPage({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 에러 아이콘
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 50,
                  color: Colors.red,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 에러 제목
              const Text(
                '앗, 문제가 발생했어요!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // 에러 메시지
              Text(
                '예상치 못한 오류가 발생했습니다.\n잠시 후 다시 시도해주세요.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // 디버그 에러 메시지 (개발 모드에서만)
              if (error.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              
              const SizedBox(height: 40),
              
              // 홈으로 가기 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(RoutePaths.splash),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB2C5B8),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '처음으로 돌아가기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 뒤로가기 버튼
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(RoutePaths.splash);
                    }
                  },
                  child: const Text(
                    '이전 페이지로',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}