import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/security_settings_model.dart';

class SecuritySettingsRepository {
  SecuritySettingsRepository({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? sharedPreferences,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _prefsFuture = sharedPreferences != null
            ? Future.value(sharedPreferences)
            : SharedPreferences.getInstance();

  static const _diaryLockKey = 'security_diary_lock';
  static const _calendarLockKey = 'security_calendar_lock';
  static const _appLockKey = 'security_app_lock';
  static const _biometricKey = 'security_biometric';
  static const _pinStorageKey = 'security_pin_hash';

  final FlutterSecureStorage _secureStorage;
  final Future<SharedPreferences> _prefsFuture;

  Future<SecuritySettingsModel> loadSettings() async {
    final prefs = await _prefsFuture;
    final hasPin = await _secureStorage.containsKey(key: _pinStorageKey);

    return SecuritySettingsModel(
      diaryLockEnabled: prefs.getBool(_diaryLockKey) ?? false,
      calendarLockEnabled: prefs.getBool(_calendarLockKey) ?? false,
      appLockEnabled: prefs.getBool(_appLockKey) ?? false,
      useBiometrics: prefs.getBool(_biometricKey) ?? false,
      hasPin: hasPin,
    );
  }

  Future<SecuritySettingsModel> updateSettings(SecuritySettingsModel model) async {
    final prefs = await _prefsFuture;
    await prefs.setBool(_diaryLockKey, model.diaryLockEnabled);
    await prefs.setBool(_calendarLockKey, model.calendarLockEnabled);
    await prefs.setBool(_appLockKey, model.appLockEnabled);
    await prefs.setBool(_biometricKey, model.useBiometrics);
    return model;
  }

  Future<void> savePin(String pin) async {
    final hash = _hashPin(pin);
    await _secureStorage.write(key: _pinStorageKey, value: hash);
  }

  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinStorageKey);
  }

  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinStorageKey);
    if (storedHash == null) {
      return false;
    }
    final incomingHash = _hashPin(pin);
    return storedHash == incomingHash;
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
