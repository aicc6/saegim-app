import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saegim/features/authentication/data/services/change_password_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

part 'change_password_notifier.g.dart';

/// 비밀번호 변경 상태 모델
class ChangePasswordState {
  final bool isLoading;
  final bool isCurrentPasswordVerifying;
  final bool isPasswordChanging;
  final String? errorMessage;
  final String? successMessage;
  final bool isCurrentPasswordValid;
  final PasswordValidation? passwordValidation;

  const ChangePasswordState({
    this.isLoading = false,
    this.isCurrentPasswordVerifying = false,
    this.isPasswordChanging = false,
    this.errorMessage,
    this.successMessage,
    this.isCurrentPasswordValid = false,
    this.passwordValidation,
  });

  /// 상태 복사 메서드
  ChangePasswordState copyWith({
    bool? isLoading,
    bool? isCurrentPasswordVerifying,
    bool? isPasswordChanging,
    String? errorMessage,
    String? successMessage,
    bool? isCurrentPasswordValid,
    PasswordValidation? passwordValidation,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      isCurrentPasswordVerifying: isCurrentPasswordVerifying ?? this.isCurrentPasswordVerifying,
      isPasswordChanging: isPasswordChanging ?? this.isPasswordChanging,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isCurrentPasswordValid: isCurrentPasswordValid ?? this.isCurrentPasswordValid,
      passwordValidation: passwordValidation ?? this.passwordValidation,
    );
  }

  @override
  String toString() {
    return 'ChangePasswordState(isLoading: $isLoading, isPasswordChanging: $isPasswordChanging, isCurrentPasswordValid: $isCurrentPasswordValid)';
  }
}

/// 비밀번호 변경 상태 관리 NotifierProvider
@riverpod
class ChangePasswordNotifier extends _$ChangePasswordNotifier {
  @override
  ChangePasswordState build() {
    return const ChangePasswordState();
  }

  /// 현재 비밀번호 확인
  Future<void> verifyCurrentPassword(String password) async {
    if (password.isEmpty) {
      state = state.copyWith(
        isCurrentPasswordValid: false,
        errorMessage: '현재 비밀번호를 입력해주세요.',
      );
      return;
    }

    state = state.copyWith(
      isCurrentPasswordVerifying: true,
      errorMessage: null,
      isCurrentPasswordValid: false,
    );

    try {
      final isValid = await ChangePasswordService.verifyCurrentPassword(password);
      
      state = state.copyWith(
        isCurrentPasswordVerifying: false,
        isCurrentPasswordValid: isValid,
        errorMessage: isValid ? null : '현재 비밀번호가 올바르지 않습니다.',
      );

      AppLogger.info('Current password verification result: $isValid');
    } catch (e) {
      AppLogger.error('Failed to verify current password', error: e);
      
      state = state.copyWith(
        isCurrentPasswordVerifying: false,
        isCurrentPasswordValid: false,
        errorMessage: '비밀번호 확인 중 오류가 발생했습니다.',
      );
    }
  }

  /// 새 비밀번호 검증
  void validateNewPassword(String password) {
    final validation = ChangePasswordService.validatePassword(password);
    
    state = state.copyWith(
      passwordValidation: validation,
      errorMessage: validation.isValid ? null : validation.errors.first,
    );
  }

  /// 비밀번호 변경
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // 입력 검증
    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      state = state.copyWith(
        errorMessage: '모든 필드를 입력해주세요.',
      );
      return false;
    }

    if (newPassword != confirmPassword) {
      state = state.copyWith(
        errorMessage: '새 비밀번호와 비밀번호 확인이 일치하지 않습니다.',
      );
      return false;
    }

    if (currentPassword == newPassword) {
      state = state.copyWith(
        errorMessage: '현재 비밀번호와 새 비밀번호가 동일합니다.',
      );
      return false;
    }

    // 새 비밀번호 강도 검증
    final validation = ChangePasswordService.validatePassword(newPassword);
    if (!validation.isValid) {
      state = state.copyWith(
        errorMessage: validation.errors.first,
        passwordValidation: validation,
      );
      return false;
    }

    state = state.copyWith(
      isPasswordChanging: true,
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final response = await ChangePasswordService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (response.success) {
        state = state.copyWith(
          isPasswordChanging: false,
          isLoading: false,
          successMessage: response.message,
        );

        AppLogger.info('Password changed successfully');
        return true;
      } else {
        state = state.copyWith(
          isPasswordChanging: false,
          isLoading: false,
          errorMessage: response.message,
        );

        AppLogger.warning('Password change failed: ${response.message}');
        return false;
      }
    } catch (e) {
      AppLogger.error('Failed to change password', error: e);
      
      state = state.copyWith(
        isPasswordChanging: false,
        isLoading: false,
        errorMessage: '비밀번호 변경 중 오류가 발생했습니다.',
      );
      return false;
    }
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

  /// 상태 초기화 (페이지 이탈 시 사용)
  void reset() {
    state = const ChangePasswordState();
  }

  /// 실시간 비밀번호 강도 검증 (입력하는 동안)
  void checkPasswordStrength(String password) {
    if (password.isEmpty) {
      state = state.copyWith(passwordValidation: null);
      return;
    }

    final validation = ChangePasswordService.validatePassword(password);
    state = state.copyWith(passwordValidation: validation);
  }
}