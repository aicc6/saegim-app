import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saegim/features/profile/data/models/user_profile_model.dart';
import 'package:saegim/features/profile/data/repositories/profile_repository.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 프로필 화면 UI 상태
class ProfileState {
  static const Object _noValue = Object();

  final UserProfileModel? profile;
  final bool isLoading;
  final bool isUpdatingProfile;
  final bool isUploadingImage;
  final bool isCheckingNickname;
  final bool? nicknameAvailable;
  final String? nicknameCheckMessage;
  final bool isSendingEmailVerification;
  final bool isWithdrawing;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isUpdatingProfile = false,
    this.isUploadingImage = false,
    this.isCheckingNickname = false,
    this.nicknameAvailable,
    this.nicknameCheckMessage,
    this.isSendingEmailVerification = false,
    this.isWithdrawing = false,
    this.errorMessage,
    this.successMessage,
  });

  factory ProfileState.initial() => const ProfileState(isLoading: true);

  ProfileState copyWith({
    UserProfileModel? profile,
    bool? isLoading,
    bool? isUpdatingProfile,
    bool? isUploadingImage,
    bool? isCheckingNickname,
    Object? nicknameAvailable = _noValue,
    Object? nicknameCheckMessage = _noValue,
    bool? isSendingEmailVerification,
    bool? isWithdrawing,
    Object? errorMessage = _noValue,
    Object? successMessage = _noValue,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isUpdatingProfile: isUpdatingProfile ?? this.isUpdatingProfile,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      isCheckingNickname: isCheckingNickname ?? this.isCheckingNickname,
      nicknameAvailable: nicknameAvailable == _noValue
          ? this.nicknameAvailable
          : nicknameAvailable as bool?,
      nicknameCheckMessage: nicknameCheckMessage == _noValue
          ? this.nicknameCheckMessage
          : nicknameCheckMessage as String?,
      isSendingEmailVerification:
          isSendingEmailVerification ?? this.isSendingEmailVerification,
      isWithdrawing: isWithdrawing ?? this.isWithdrawing,
      errorMessage: errorMessage == _noValue
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: successMessage == _noValue
          ? this.successMessage
          : successMessage as String?,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._repository) : super(ProfileState.initial()) {
    _loadProfile();
  }

  final ProfileRepository _repository;

  Future<void> _loadProfile() async {
    await refreshProfile();
  }

  Future<void> refreshProfile() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );
    try {
      final profile = await _repository.fetchProfile();
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '프로필 정보를 불러오지 못했습니다.',
        error: e,
        stackTrace: stackTrace,
        tag: 'ProfileNotifier',
      );
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> checkNickname(String nickname) async {
    if (nickname.isEmpty) {
      state = state.copyWith(
        nicknameAvailable: false,
        nicknameCheckMessage: '닉네임을 입력해주세요.',
      );
      return;
    }

    state = state.copyWith(
      isCheckingNickname: true,
      nicknameCheckMessage: null,
      successMessage: null,
      errorMessage: null,
    );

    try {
      final available = await _repository.checkNicknameAvailability(nickname);
      state = state.copyWith(
        isCheckingNickname: false,
        nicknameAvailable: available,
        nicknameCheckMessage: available ? '사용 가능한 닉네임입니다.' : '이미 사용 중인 닉네임입니다.',
      );
    } catch (e) {
      state = state.copyWith(
        isCheckingNickname: false,
        nicknameAvailable: false,
        nicknameCheckMessage: '닉네임 중복 확인 중 오류가 발생했습니다.',
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateProfile({required String nickname}) async {
    final currentProfile = state.profile;
    if (currentProfile == null) {
      return;
    }

    if (nickname.isEmpty) {
      state = state.copyWith(errorMessage: '닉네임을 입력해주세요.');
      return;
    }

    state = state.copyWith(
      isUpdatingProfile: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final result = await _repository.updateProfile(
        ProfileUpdateRequest(
          nickname: nickname,
          profileImageUrl: currentProfile.profileImageUrl,
        ),
      );

      state = state.copyWith(
        isUpdatingProfile: false,
        profile: currentProfile.copyWith(
          nickname: result.nickname,
          profileImageUrl:
              result.profileImageUrl ?? currentProfile.profileImageUrl,
        ),
        nicknameAvailable: null,
        nicknameCheckMessage: null,
        successMessage: '프로필이 업데이트되었습니다.',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '프로필 업데이트 실패',
        error: e,
        stackTrace: stackTrace,
        tag: 'ProfileNotifier',
      );
      state = state.copyWith(
        isUpdatingProfile: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> uploadProfileImage(XFile file) async {
    final currentProfile = state.profile;
    if (currentProfile == null) {
      return;
    }

    state = state.copyWith(
      isUploadingImage: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final imageUrl = await _repository.uploadProfileImage(file);
      state = state.copyWith(
        isUploadingImage: false,
        profile: currentProfile.copyWith(profileImageUrl: imageUrl),
        successMessage: '프로필 이미지가 업데이트되었습니다.',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '프로필 이미지 업로드 실패',
        error: e,
        stackTrace: stackTrace,
        tag: 'ProfileNotifier',
      );
      state = state.copyWith(
        isUploadingImage: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> sendEmailChangeVerification(String newEmail) async {
    if (newEmail.isEmpty) {
      state = state.copyWith(errorMessage: '새 이메일을 입력해주세요.');
      return;
    }

    state = state.copyWith(
      isSendingEmailVerification: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      await _repository.sendEmailChangeVerification(
        EmailVerificationRequest(newEmail),
      );
      state = state.copyWith(
        isSendingEmailVerification: false,
        successMessage: '인증 메일을 전송했어요. 받은 메일의 안내를 따라주세요.',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        '이메일 변경 인증 요청 실패',
        error: e,
        stackTrace: stackTrace,
        tag: 'ProfileNotifier',
      );
      state = state.copyWith(
        isSendingEmailVerification: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> withdrawAccount({
    required String password,
    String reason = '기타',
    String? detailedReason,
  }) async {
    state = state.copyWith(
      isWithdrawing: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      await _repository.requestAccountWithdrawal(
        WithdrawAccountRequest(
          password: password,
          reason: reason,
          detailedReason: detailedReason,
        ),
      );

      state = state.copyWith(
        isWithdrawing: false,
        successMessage: '계정 탈퇴가 완료되었습니다.',
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        '계정 탈퇴 실패',
        error: e,
        stackTrace: stackTrace,
        tag: 'ProfileNotifier',
      );
      state = state.copyWith(isWithdrawing: false, errorMessage: e.toString());
      return false;
    }
  }

  void clearFeedbackMessages() {
    state = state.copyWith(successMessage: null, errorMessage: null);
  }

  void resetNicknameValidation() {
    state = state.copyWith(nicknameAvailable: null, nicknameCheckMessage: null);
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
      final repository = ref.watch(profileRepositoryProvider);
      return ProfileNotifier(repository);
    });
