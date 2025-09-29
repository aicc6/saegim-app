import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/core/services/auth_storage_service.dart';
import 'package:saegim/features/authentication/presentation/riverpod/auth_notifier.dart';
import 'package:saegim/features/profile/presentation/providers/profile_notifier.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';
import 'package:saegim/shared/utils/app_logger.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late final TextEditingController _nicknameController;
  late final TextEditingController _emailController;
  late final TextEditingController _withdrawPasswordController;
  final _imagePicker = ImagePicker();
  late final GoRouter _router; // GoRouter 참조 저장
  bool _isGoogleUser = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController();
    _emailController = TextEditingController();
    _withdrawPasswordController = TextEditingController();

    // 프로필 페이지 진입 시 자동으로 프로필 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(profileNotifierProvider.notifier);
      notifier.resetNicknameValidation(); // 닉네임 검증 상태 초기화
      notifier.refreshProfile();
      _checkUserType();
    });
  }

  Future<void> _checkUserType() async {
    final isGoogleUser = await AuthStorageService.instance.isGoogleUser();
    if (mounted) {
      setState(() {
        _isGoogleUser = isGoogleUser;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // GoRouter 참조를 안전하게 저장
    _router = GoRouter.of(context);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _emailController.dispose();
    _withdrawPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);

    // 초기 프로필 로드 시 닉네임 설정
    if (profileState.profile != null &&
        _nicknameController.text.isEmpty &&
        profileState.profile!.nickname.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nicknameController.text = profileState.profile!.nickname;
      });
    }

    // Listen for state changes to handle side effects
    ref.listen<ProfileState>(profileNotifierProvider, (previous, next) {
      if (previous?.profile?.nickname != next.profile?.nickname) {
        _nicknameController.text = next.profile?.nickname ?? '';
      }

      final messenger = ScaffoldMessenger.of(context);
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(next.errorMessage!)));
        ref.read(profileNotifierProvider.notifier).clearFeedbackMessages();
      } else if (next.successMessage != null &&
          next.successMessage!.isNotEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(next.successMessage!)));
        ref.read(profileNotifierProvider.notifier).clearFeedbackMessages();
      }
    });

    return Scaffold(
      appBar: const CommonAppBar(showBackButton: true, title: '프로필'),
      body: RefreshIndicator(
        onRefresh: ref.read(profileNotifierProvider.notifier).refreshProfile,
        child: profileState.isLoading && profileState.profile == null
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      '프로필을 불러오는 중...',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildProfileInformationCard(context, profileState),
                    const SizedBox(height: 16),
                    _buildAccountCard(context, profileState),
                    const SizedBox(height: 16),
                    _buildLogoutButton(context),
                    const SizedBox(height: 24), // 하단 여백
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileInformationCard(
    BuildContext context,
    ProfileState state,
  ) {
    final profile = state.profile;
    if (profile == null) {
      return _buildPlaceholderCard('프로필 정보를 불러올 수 없어요. 다시 시도해주세요.');
    }

    return _buildCard(
      child: Column(
        children: [
          // Profile Header Section
          Column(
            children: [
              _buildAvatar(state),
              const SizedBox(height: 16),
              Text(
                profile.nickname.isNotEmpty ? profile.nickname : '닉네임 없음',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3A59),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  profile.maskedEmail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Divider
          Container(
            height: 1,
            color: Colors.grey[200],
            margin: const EdgeInsets.only(bottom: 24),
          ),

          // Edit Profile Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '프로필 편집',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3A59),
                ),
              ),
              const SizedBox(height: 16),

              // Nickname Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '닉네임',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _nicknameController,
                          enabled: !state.isUpdatingProfile,
                          decoration: InputDecoration(
                            hintText: '닉네임 입력',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (_) => ref
                              .read(profileNotifierProvider.notifier)
                              .resetNicknameValidation(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 70, // 고정 너비로 변경
                        height: 44,
                        child: OutlinedButton(
                          onPressed: state.isCheckingNickname
                              ? null
                              : () => ref
                                    .read(profileNotifierProvider.notifier)
                                    .checkNickname(
                                      _nicknameController.text.trim(),
                                    ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFB2C5B8)),
                            foregroundColor: const Color(0xFF2E3A59),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: state.isCheckingNickname
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  '중복\n확인',
                                  style: TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (state.nicknameCheckMessage != null && 
                      state.nicknameCheckMessage!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Icon(
                            state.nicknameAvailable == true
                                ? Icons.check_circle
                                : Icons.error,
                            size: 16,
                            color: state.nicknameAvailable == true
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              state.nicknameCheckMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: state.nicknameAvailable == true
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Email Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '이메일',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      TextButton(
                        onPressed: state.isSendingEmailVerification
                            ? null
                            : () => _showEmailChangeSheet(context),
                        child: state.isSendingEmailVerification
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('변경'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      profile.maskedEmail,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: state.isUpdatingProfile
                      ? null
                      : () => ref
                            .read(profileNotifierProvider.notifier)
                            .updateProfile(
                              nickname: _nicknameController.text.trim(),
                            ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E3A59),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: state.isUpdatingProfile
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          '프로필 업데이트',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ProfileState state) {
    final profile = state.profile;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFFE8F0EB),
            backgroundImage: profile?.profileImageUrl != null
                ? NetworkImage(profile!.profileImageUrl!)
                : null,
            child: profile?.profileImageUrl == null
                ? const Icon(Icons.person, size: 50, color: Color(0xFF9EB5A6))
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2E3A59),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: state.isUploadingImage ? null : _pickImage,
              icon: state.isUploadingImage
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              iconSize: 20,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountCard(BuildContext context, ProfileState state) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '계정 설정',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E3A59),
                    ),
                  ),
                  Text(
                    '계정 관련 설정을 관리합니다.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Color(0xFF6B7280)),
            title: const Text(
              '고객센터 문의',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2E3A59),
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
            onTap: () => context.push(RoutePaths.support),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 1),
          // 이메일 사용자에게만 비밀번호 변경 옵션 표시
          if (!_isGoogleUser) ...[
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Color(0xFF6B7280)),
              title: const Text(
                '비밀번호 변경',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2E3A59),
                ),
              ),
              subtitle: const Text(
                '계정 보안을 위해 주기적으로 변경해주세요.',
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
              trailing: const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
              onTap: () => context.push('/settings/change-password'),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: 1),
          ],
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red[600]),
            title: Text(
              '계정 탈퇴',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red[600],
              ),
            ),
            subtitle: const Text(
              '탈퇴 시 모든 데이터가 30일 후 영구 삭제됩니다.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            trailing: state.isWithdrawing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
            onTap: state.isWithdrawing
                ? null
                : () => _showWithdrawDialog(context),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderCard(String message) {
    return _buildCard(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF2E3A59)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: ref
                .read(profileNotifierProvider.notifier)
                .refreshProfile,
            child: const Text('다시 불러오기'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
      );

      if (image != null) {
        await ref
            .read(profileNotifierProvider.notifier)
            .uploadProfileImage(image);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미지를 불러오지 못했습니다. 다시 시도해주세요.')),
      );
    }
  }

  void _showEmailChangeSheet(BuildContext context) {
    _emailController.clear();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.email_outlined,
                      color: Color(0xFF2E3A59),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이메일 변경',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3A59),
                        ),
                      ),
                      Text(
                        '새 이메일 주소로 인증 메일을 발송합니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBAE6FD), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF0284C7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        '메일함을 확인하여 인증을 완료해야 변경이 반영됩니다.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Email input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '새 이메일 주소',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'example@email.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        foregroundColor: const Color(0xFF6B7280),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        final email = _emailController.text.trim();
                        if (email.isEmpty) return;

                        Navigator.of(context).pop();
                        ref
                            .read(profileNotifierProvider.notifier)
                            .sendEmailChangeVerification(email);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E3A59),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '인증 메일 발송',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    _withdrawPasswordController.clear();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warning icon - reduced size
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[600],
                      size: 20,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Title - reduced font size
                  const Text(
                    '계정 탈퇴',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3A59),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Description - shortened and reduced font size
                  const Text(
                    '탈퇴 후 모든 데이터가 30일 후 영구 삭제됩니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Warning card - more compact
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: const Color(0xFFFECACA),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.red[700],
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            '다이어리, 프로필 등 모든 데이터가 삭제됩니다.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Password input - more compact
                  TextField(
                    controller: _withdrawPasswordController,
                    obscureText: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: '현재 비밀번호',
                      labelStyle: const TextStyle(fontSize: 12),
                      hintText: '비밀번호 입력',
                      hintStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      isDense: true,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action buttons - more compact
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            foregroundColor: const Color(0xFF6B7280),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                          child: const Text('취소'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final password = _withdrawPasswordController.text
                                .trim();
                            if (password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('비밀번호를 입력해주세요.'),
                                  backgroundColor: Colors.red[600],
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            Navigator.of(context).pop();

                            try {
                              AppLogger.debug(
                                '계정 탈퇴 API 호출 시작',
                                'ProfilePage',
                              );
                              final success = await ref
                                  .read(profileNotifierProvider.notifier)
                                  .withdrawAccount(password: password);

                              AppLogger.debug(
                                '계정 탈퇴 API 결과: $success',
                                'ProfilePage',
                              );

                              if (success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('계정 탈퇴가 완료되었습니다.'),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(milliseconds: 800),
                                    ),
                                  );
                                }

                                // context 상태에 관계없이 로그아웃 처리
                                AppLogger.debug(
                                  '로그아웃 시작 (context mounted: ${context.mounted})',
                                  'ProfilePage',
                                );
                                await ref
                                    .read(authNotifierProvider.notifier)
                                    .logout();
                                AppLogger.debug(
                                  '로그아웃 완료',
                                  'ProfilePage',
                                );

                                // 저장된 GoRouter 참조를 사용한 안전한 페이지 이동
                                AppLogger.debug(
                                  '저장된 GoRouter를 사용한 페이지 이동',
                                  'ProfilePage',
                                );
                                try {
                                  _router.go(RoutePaths.authLogin);
                                  AppLogger.debug(
                                    'GoRouter 페이지 이동 명령 완료',
                                    'ProfilePage',
                                  );
                                } catch (e) {
                                  AppLogger.error(
                                    'GoRouter 페이지 이동 실패',
                                    tag: 'ProfilePage',
                                    error: e,
                                  );
                                  // 마지막 수단으로 앱 종료 후 재시작 유도
                                  AppLogger.warning(
                                    '앱 재시작을 위해 종료 시도',
                                    'ProfilePage',
                                  );
                                }
                              } else if (!success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('계정 탈퇴에 실패했습니다. 다시 시도해주세요.'),
                                    backgroundColor: Colors.red[600],
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else if (!context.mounted) {
                                AppLogger.warning(
                                  'context가 unmounted 상태 (success: $success)',
                                  'ProfilePage',
                                );
                              }
                            } catch (e, stackTrace) {
                              AppLogger.error(
                                '계정 탈퇴 처리 중 예외 발생',
                                tag: 'ProfilePage',
                                error: e,
                                stackTrace: stackTrace,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('오류가 발생했습니다. 다시 시도해주세요.'),
                                    backgroundColor: Colors.red[600],
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                          child: const Text('탈퇴하기'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '계정 관리',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showLogoutDialog(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFEF4444)),
                foregroundColor: const Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '로그아웃',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '로그아웃',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A59),
            ),
          ),
          content: const Text(
            '정말 로그아웃하시겠습니까?',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await ref.read(authNotifierProvider.notifier).logout();
                  _router.go(RoutePaths.authLogin);
                } catch (e) {
                  AppLogger.error(
                    '로그아웃 에러',
                    tag: 'ProfilePage',
                    error: e,
                  );
                  // 에러 발생시에도 로그인 페이지로 이동
                  _router.go(RoutePaths.authLogin);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
              ),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );
  }
}
