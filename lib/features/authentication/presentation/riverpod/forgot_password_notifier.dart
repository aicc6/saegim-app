import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saegim/features/authentication/data/models/forgot_password_models.dart';
import 'package:saegim/features/authentication/data/services/forgot_password_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

part 'forgot_password_notifier.g.dart';

/// 비밀번호 찾기 상태 관리 NotifierProvider
@riverpod
class ForgotPasswordNotifier extends _$ForgotPasswordNotifier {
  @override
  ForgotPasswordState build() {
    return const ForgotPasswordState();
  }

  /// 에러 메시지 초기화
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// 성공 메시지 초기화
  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }

  /// 모든 메시지 초기화
  void clearMessages() {
    state = state.copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }

  /// 상태 초기화 (처음부터 다시 시작)
  void resetState() {
    state = const ForgotPasswordState();
  }

  /// 이메일 설정
  void setEmail(String email) {
    state = state.copyWith(email: email);
  }

  /// 1단계: 비밀번호 재설정 이메일 발송
  Future<bool> sendPasswordResetEmail(String email) async {
    // 이메일 형식 검증
    if (!ForgotPasswordService.isValidEmail(email)) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '올바른 이메일 주소를 입력해주세요.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      AppLogger.info('Sending password reset email to: $email');

      final response = await ForgotPasswordService.sendPasswordResetEmail(email);

      if (response.success && response.emailSent) {
        // 이메일 발송 성공
        state = state.copyWith(
          email: email,
          isLoading: false,
          emailSent: true,
          currentStep: ForgotPasswordStep.emailSent,
          successMessage: '비밀번호 재설정 링크가 이메일로 발송되었습니다.',
        );

        AppLogger.info('Password reset email sent successfully to: $email');
        return true;
      } else if (response.isSocialAccount) {
        // 소셜 계정인 경우
        state = state.copyWith(
          isLoading: false,
          errorMessage: '소셜 계정은 해당 서비스에서 비밀번호를 변경해주세요.',
        );
        return false;
      } else if (response.redirectToErrorPage) {
        // 에러 페이지로 리다이렉트 필요
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message.isNotEmpty 
              ? response.message 
              : '계정을 찾을 수 없습니다.',
        );
        return false;
      } else {
        // 기타 실패
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message.isNotEmpty 
              ? response.message 
              : '이메일 발송에 실패했습니다.',
        );
        return false;
      }
    } catch (e) {
      AppLogger.error(
        'Failed to send password reset email',
        error: e,
      );

      String errorMessage = '이메일 발송 중 오류가 발생했습니다.';
      if (e.toString().contains('network') || 
          e.toString().contains('connection')) {
        errorMessage = '네트워크 연결을 확인해주세요.';
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );
      return false;
    }
  }

  /// 이전 단계로 돌아가기
  void goToPreviousStep() {
    switch (state.currentStep) {
      case ForgotPasswordStep.emailInput:
        // 첫 번째 단계에서는 돌아갈 곳이 없음
        break;
      case ForgotPasswordStep.emailSent:
        state = state.copyWith(
          currentStep: ForgotPasswordStep.emailInput,
          emailSent: false,
          successMessage: null,
          errorMessage: null,
        );
        break;
    }
  }

  /// 비밀번호 재설정 링크 재발송
  Future<bool> resendPasswordResetEmail() async {
    final email = state.email;
    if (email == null || email.isEmpty) {
      state = state.copyWith(
        errorMessage: '이메일 정보가 없습니다.',
      );
      return false;
    }

    // 기존 상태를 유지하면서 이메일 재발송
    return await sendPasswordResetEmail(email);
  }

  /// 현재 단계별 유효성 검사
  bool canProceedToNextStep() {
    switch (state.currentStep) {
      case ForgotPasswordStep.emailInput:
        return state.email != null && 
               state.email!.isNotEmpty && 
               ForgotPasswordService.isValidEmail(state.email!) &&
               state.emailSent;
      case ForgotPasswordStep.emailSent:
        return true;
    }
  }
}