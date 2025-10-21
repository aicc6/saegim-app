import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saegim/features/settings/data/models/security_settings_model.dart';
import 'package:saegim/features/settings/data/repositories/security_settings_repository.dart';

final securitySettingsRepositoryProvider = Provider<SecuritySettingsRepository>((ref) {
  return SecuritySettingsRepository();
});

class SecuritySettingsNotifier extends StateNotifier<AsyncValue<SecuritySettingsModel>> {
  SecuritySettingsNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    _load();
  }

  final SecuritySettingsRepository _repository;

  Future<void> _load() async {
    try {
      final settings = await _repository.loadSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _load();
  }

  Future<bool> verifyPin(String pin) async {
    return _repository.verifyPin(pin);
  }

  Future<void> setPin(String pin) async {
    await _repository.savePin(pin);
    state.whenData((value) {
      state = AsyncValue.data(value.copyWith(hasPin: true));
    });
  }

  Future<void> clearPin() async {
    await _repository.clearPin();
    state.whenData((value) {
      state = AsyncValue.data(
        value.copyWith(
          hasPin: false,
          diaryLockEnabled: false,
          calendarLockEnabled: false,
          appLockEnabled: false,
        ),
      );
    });
    await _repository.updateSettings(SecuritySettingsModel.initial());
  }

  Future<void> updateLocks({
    bool? diaryLockEnabled,
    bool? calendarLockEnabled,
    bool? appLockEnabled,
    bool? useBiometrics,
  }) async {
    final current = state.value ?? SecuritySettingsModel.initial();
    final updated = current.copyWith(
      diaryLockEnabled: diaryLockEnabled,
      calendarLockEnabled: calendarLockEnabled,
      appLockEnabled: appLockEnabled,
      useBiometrics: useBiometrics,
    );
    await _repository.updateSettings(updated);
    state = AsyncValue.data(updated);
  }
}

final securitySettingsProvider =
    StateNotifierProvider<SecuritySettingsNotifier, AsyncValue<SecuritySettingsModel>>((ref) {
  final repository = ref.watch(securitySettingsRepositoryProvider);
  return SecuritySettingsNotifier(repository);
});
