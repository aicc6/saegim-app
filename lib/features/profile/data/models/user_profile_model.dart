/// 사용자 프로필 정보 모델
class UserProfileModel {
  final String userId;
  final String email;
  final String nickname;
  final String? profileImageUrl;
  final String? accountType;
  final String? provider;
  final bool isActive;
  final DateTime? createdAt;

  const UserProfileModel({
    required this.userId,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
    this.accountType,
    this.provider,
    this.isActive = true,
    this.createdAt,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      userId: json['user_id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      nickname: json['nickname']?.toString() ?? '',
      profileImageUrl: json['profile_image_url']?.toString(),
      accountType: json['account_type']?.toString(),
      provider: json['provider']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'email': email,
      'nickname': nickname,
      'profile_image_url': profileImageUrl,
      'account_type': accountType,
      'provider': provider,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserProfileModel copyWith({
    String? userId,
    String? email,
    String? nickname,
    String? profileImageUrl,
    String? accountType,
    String? provider,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserProfileModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      accountType: accountType ?? this.accountType,
      provider: provider ?? this.provider,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 이메일을 중간에 마스킹하여 표시합니다.
  String get maskedEmail {
    final emailParts = email.split('@');
    if (emailParts.length != 2) {
      return email;
    }

    final local = emailParts.first;
    final domain = emailParts.last;

    if (local.isEmpty) {
      return email;
    }

    if (local.length == 1) {
      return '${local[0]}***@$domain';
    }

    if (local.length == 2) {
      return '${local[0]}*@$domain';
    }

    final visiblePrefix = local.substring(0, 2);
    final masked = '*' * (local.length - 2);
    return '$visiblePrefix$masked@$domain';
  }
}

/// 프로필 업데이트 요청 모델
class ProfileUpdateRequest {
  final String nickname;
  final String? profileImageUrl;

  const ProfileUpdateRequest({required this.nickname, this.profileImageUrl});

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      if (profileImageUrl != null && profileImageUrl!.isNotEmpty)
        'profile_image_url': profileImageUrl,
    };
  }
}

/// 프로필 업데이트 결과 모델
class ProfileUpdateResult {
  final String nickname;
  final String? profileImageUrl;

  const ProfileUpdateResult({required this.nickname, this.profileImageUrl});

  factory ProfileUpdateResult.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateResult(
      nickname: json['nickname']?.toString() ?? '',
      profileImageUrl: json['profile_image_url']?.toString(),
    );
  }
}

/// 이메일 변경 인증 요청
class EmailVerificationRequest {
  final String newEmail;

  const EmailVerificationRequest(this.newEmail);

  Map<String, dynamic> toJson() {
    return {'new_email': newEmail};
  }
}

/// 계정 탈퇴 요청 모델
class WithdrawAccountRequest {
  final String password;
  final String reason;
  final String? detailedReason;

  const WithdrawAccountRequest({
    this.password = '',
    this.reason = '기타',
    this.detailedReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'password': password,
      'reason': reason,
      if (detailedReason != null && detailedReason!.isNotEmpty)
        'detailed_reason': detailedReason,
    };
  }
}
