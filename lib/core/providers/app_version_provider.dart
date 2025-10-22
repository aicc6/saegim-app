import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/core/models/app_version.dart';
import 'package:saegim/core/services/app_version_service.dart';
import 'package:saegim/shared/utils/app_logger.dart';

const _unset = Object();

class AppVersionState {
  const AppVersionState({
    this.isChecking = false,
    this.versionInfo,
    this.errorMessage,
    this.lastCheckedAt,
    this.lastFailedAt,
    this.optionalUpdateDismissed = false,
  });

  final bool isChecking;
  final CheckAppVersionResponse? versionInfo;
  final String? errorMessage;
  final DateTime? lastCheckedAt;
  final DateTime? lastFailedAt;
  final bool optionalUpdateDismissed;

  bool get requiresForceUpdate =>
      versionInfo?.hasUpdate == true && versionInfo?.isMandatory == true;

  bool get hasOptionalUpdate =>
      versionInfo?.hasUpdate == true &&
      versionInfo?.isMandatory == false &&
      !optionalUpdateDismissed;

  AppVersionState copyWith({
    bool? isChecking,
    CheckAppVersionResponse? versionInfo,
    Object? errorMessage = _unset,
    DateTime? lastCheckedAt,
    DateTime? lastFailedAt,
    bool? optionalUpdateDismissed,
  }) {
    return AppVersionState(
      isChecking: isChecking ?? this.isChecking,
      versionInfo: versionInfo ?? this.versionInfo,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      lastFailedAt: lastFailedAt ?? this.lastFailedAt,
      optionalUpdateDismissed:
          optionalUpdateDismissed ?? this.optionalUpdateDismissed,
    );
  }
}

class AppVersionNotifier extends StateNotifier<AppVersionState> {
  AppVersionNotifier({required AppVersionService service})
    : _service = service,
      super(const AppVersionState());

  final AppVersionService _service;
  static const Duration _defaultThrottle = Duration(minutes: 5);

  void hydrateFromCache() {
    final cached = _service.cachedResponse;
    if (cached == null) {
      return;
    }

    state = state.copyWith(
      versionInfo: cached,
      lastCheckedAt: _service.lastCheckedAt,
      optionalUpdateDismissed: cached.hasUpdate && !cached.isMandatory
          ? state.optionalUpdateDismissed
          : false,
    );
  }

  Future<void> checkVersion({bool force = false}) async {
    final now = DateTime.now();

    if (!force) {
      if (state.isChecking) {
        return;
      }

      final lastCheckedAt = state.lastCheckedAt;
      if (lastCheckedAt != null &&
          now.difference(lastCheckedAt) < _defaultThrottle) {
        return;
      }
    }

    state = state.copyWith(isChecking: true, errorMessage: null);

    try {
      final response = await _service.checkAppVersion();

      state = state.copyWith(
        isChecking: false,
        versionInfo: response,
        errorMessage: null,
        lastCheckedAt: now,
        optionalUpdateDismissed: response.hasUpdate && !response.isMandatory
            ? false
            : state.optionalUpdateDismissed,
      );
    } catch (error, stackTrace) {
      AppLogger.error(
        '앱 버전 체크 실패: $error',
        tag: 'AppVersionNotifier',
        error: error,
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isChecking: false,
        errorMessage: error.toString(),
        lastFailedAt: now,
      );
    }
  }

  void dismissOptionalUpdate() {
    if (!state.hasOptionalUpdate) {
      return;
    }

    state = state.copyWith(optionalUpdateDismissed: true);
  }
}

final appVersionProvider =
    StateNotifierProvider<AppVersionNotifier, AppVersionState>((ref) {
      final notifier = AppVersionNotifier(service: AppVersionService.instance);
      notifier.hydrateFromCache();
      unawaited(notifier.checkVersion(force: true));
      return notifier;
    });
