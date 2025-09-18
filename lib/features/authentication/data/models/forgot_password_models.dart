/// 비밀번호 찾기 관련 데이터 모델들

/// 비밀번호 재설정 이메일 요청 모델
class PasswordResetEmailRequest {
  final String email;

  const PasswordResetEmailRequest({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }

  factory PasswordResetEmailRequest.fromJson(Map<String, dynamic> json) {
    return PasswordResetEmailRequest(
      email: json['email'] as String,
    );
  }
}

/// 비밀번호 재설정 이메일 응답 모델
class PasswordResetEmailResponse {
  final bool success;
  final String message;
  final bool isSocialAccount;
  final bool emailSent;
  final bool redirectToErrorPage;

  const PasswordResetEmailResponse({
    required this.success,
    required this.message,
    this.isSocialAccount = false,
    this.emailSent = false,
    this.redirectToErrorPage = false,
  });

  factory PasswordResetEmailResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetEmailResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      isSocialAccount: json['is_social_account'] as bool? ?? false,
      emailSent: json['email_sent'] as bool? ?? false,
      redirectToErrorPage: json['redirect_to_error_page'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'is_social_account': isSocialAccount,
      'email_sent': emailSent,
      'redirect_to_error_page': redirectToErrorPage,
    };
  }
}

/// 비밀번호 재설정 인증코드 확인 요청 모델
class VerifyPasswordResetCodeRequest {
  final String email;
  final String verificationCode;

  const VerifyPasswordResetCodeRequest({
    required this.email,
    required this.verificationCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'verification_code': verificationCode,
    };
  }

  factory VerifyPasswordResetCodeRequest.fromJson(Map<String, dynamic> json) {
    return VerifyPasswordResetCodeRequest(
      email: json['email'] as String,
      verificationCode: json['verification_code'] as String,
    );
  }
}

/// 비밀번호 재설정 요청 모델
class ResetPasswordRequest {
  final String email;
  final String verificationCode;
  final String newPassword;

  const ResetPasswordRequest({
    required this.email,
    required this.verificationCode,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'verification_code': verificationCode,
      'new_password': newPassword,
    };
  }

  factory ResetPasswordRequest.fromJson(Map<String, dynamic> json) {
    return ResetPasswordRequest(
      email: json['email'] as String,
      verificationCode: json['verification_code'] as String,
      newPassword: json['new_password'] as String,
    );
  }
}

/// 기본 API 응답 모델
class BaseResponse<T> {
  final bool success;
  final String message;
  final T? data;

  const BaseResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return BaseResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
    );
  }

  Map<String, dynamic> toJson([Object? Function(T)? toJsonT]) {
    return {
      'success': success,
      'message': message,
      'data': data != null && toJsonT != null ? toJsonT(data as T) : data,
    };
  }
}

/// 비밀번호 찾기 프로세스 상태
enum ForgotPasswordStep {
  /// 이메일 입력 단계
  emailInput,
  
  /// 이메일 발송 완료 단계
  emailSent,
}

/// 비밀번호 찾기 상태
class ForgotPasswordState {
  final ForgotPasswordStep currentStep;
  final String? email;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final bool emailSent;

  const ForgotPasswordState({
    this.currentStep = ForgotPasswordStep.emailInput,
    this.email,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.emailSent = false,
  });

  ForgotPasswordState copyWith({
    ForgotPasswordStep? currentStep,
    String? email,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? emailSent,
  }) {
    return ForgotPasswordState(
      currentStep: currentStep ?? this.currentStep,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      emailSent: emailSent ?? this.emailSent,
    );
  }

  @override
  String toString() {
    return 'ForgotPasswordState('
        'currentStep: $currentStep, '
        'email: $email, '
        'isLoading: $isLoading, '
        'emailSent: $emailSent'
        ')';
  }
}