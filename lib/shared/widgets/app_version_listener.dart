import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/core/models/app_version.dart';
import 'package:saegim/core/providers/app_version_provider.dart';
import 'package:saegim/shared/utils/app_logger.dart';
import 'package:saegim/shared/widgets/app_update_dialog.dart';

class AppVersionListener extends ConsumerStatefulWidget {
  const AppVersionListener({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppVersionListener> createState() => _AppVersionListenerState();
}

class _AppVersionListenerState extends ConsumerState<AppVersionListener>
    with WidgetsBindingObserver {
  bool _mandatoryDialogVisible = false;
  bool _optionalDialogVisible = false;
  ProviderSubscription<AppVersionState>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _subscription = ref.listenManual<AppVersionState>(
      appVersionProvider,
      _handleStateChange,
    );

    final initialState = ref.read(appVersionProvider);
    _handleStateChange(null, initialState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        ref.read(appVersionProvider.notifier).checkVersion(force: true),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(appVersionProvider.notifier).checkVersion());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.close();
    super.dispose();
  }

  void _handleStateChange(AppVersionState? previous, AppVersionState next) {
    if (!mounted) {
      return;
    }

    if (next.requiresForceUpdate) {
      if (!_mandatoryDialogVisible) {
        _showUpdateDialog(next.versionInfo!, isMandatory: true);
      }
      return;
    }

    if (next.hasOptionalUpdate) {
      if (!_optionalDialogVisible) {
        _showUpdateDialog(next.versionInfo!, isMandatory: false);
      }
    } else if (_optionalDialogVisible) {
      _optionalDialogVisible = false;
    }

    if (next.errorMessage != null &&
        next.errorMessage != previous?.errorMessage) {
      AppLogger.warning(
        '앱 버전 체크 실패: ${next.errorMessage}',
        'AppVersionListener',
      );
    }
  }

  Future<void> _showUpdateDialog(
    CheckAppVersionResponse versionInfo, {
    required bool isMandatory,
  }) async {
    if (!mounted) {
      return;
    }

    if (isMandatory) {
      _mandatoryDialogVisible = true;
    } else {
      _optionalDialogVisible = true;
    }

    // 프레임 렌더링 완료 후 다이얼로그 표시
    await Future.delayed(Duration.zero);

    if (!mounted) {
      return;
    }

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: !isMandatory,
        builder: (dialogContext) {
          return AppUpdateDialog(
            versionInfo: versionInfo,
            onSkip: () {
              if (!isMandatory) {
                ref.read(appVersionProvider.notifier).dismissOptionalUpdate();
              }
            },
          );
        },
      );

      // showDialog 성공 후에만 cleanup 실행
      if (!mounted) {
        return;
      }

      if (isMandatory) {
        _mandatoryDialogVisible = false;
      } else {
        _optionalDialogVisible = false;
        ref.read(appVersionProvider.notifier).dismissOptionalUpdate();
      }
    } catch (e, stack) {
      AppLogger.error(
        '업데이트 다이얼로그 표시 실패: $e',
        tag: 'AppVersionListener',
        error: e,
        stackTrace: stack,
      );

      // showDialog 실패 시 플래그만 초기화 (dismissed는 설정하지 않음)
      if (isMandatory) {
        _mandatoryDialogVisible = false;
      } else {
        _optionalDialogVisible = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
