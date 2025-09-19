import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:saegim/features/authentication/data/services/change_password_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

part 'change_password_notifier.g.dart';

/// 비밀번호 변경 상태 모델
class ChangePasswordState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ChangePasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  /// 상태 복사 메서드
  ChangePasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  @override
  String toString() {
    return 'ChangePasswordState(isLoading: $isLoading, errorMessage: $errorMessage)';
  }
}

/// 비밀번호 변경 상태 관리 NotifierProvider
@riverpod
class ChangePasswordNotifier extends _$ChangePasswordNotifier {
  @override
  ChangePasswordState build() {
    return const ChangePasswordState();
  }

  /// 새 비밀번호 검증
  String? validateNewPassword(String password) {
    return ChangePasswordService.validatePassword(password);
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
    final validationError = ChangePasswordService.validatePassword(newPassword);
    if (validationError != null) {
      state = state.copyWith(
        errorMessage: validationError,
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final success = await ChangePasswordService.changePassword(
        currentPassword,
        newPassword,
      );

      if (success) {
        state = state.copyWith(
          isLoading: false,
          successMessage: '비밀번호가 성공적으로 변경되었습니다.',
        );

        AppLogger.info('Password changed successfully');
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '비밀번호 변경에 실패했습니다.',
        );

        AppLogger.warning('Password change failed');
        return false;
      }
    } on ChangePasswordException catch (e) {
      AppLogger.error('Password change failed', error: e);

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      AppLogger.error('Unexpected error during password change', error: e);

      state = state.copyWith(
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
}