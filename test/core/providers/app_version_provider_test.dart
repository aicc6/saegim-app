import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:saegim/core/models/app_version.dart';
import 'package:saegim/core/providers/app_version_provider.dart';
import 'package:saegim/core/services/app_version_service.dart';

class FakeAppVersionService implements AppVersionService {
  FakeAppVersionService({List<CheckAppVersionResponse>? responses})
    : _responses = Queue.of(responses ?? const []);

  final Queue<CheckAppVersionResponse> _responses;
  CheckAppVersionResponse? _cachedResponse;
  DateTime? _lastCheckedAt;

  void setCached(CheckAppVersionResponse response, DateTime timestamp) {
    _cachedResponse = response;
    _lastCheckedAt = timestamp;
  }

  @override
  Future<CheckAppVersionResponse> checkAppVersion() async {
    final response = _responses.isNotEmpty
        ? _responses.removeFirst()
        : _cachedResponse;
    if (response == null) {
      throw StateError('No response configured');
    }
    _cachedResponse = response;
    _lastCheckedAt = DateTime.now();
    return response;
  }

  @override
  Future<AppVersionInfo?> getLatestVersion() async =>
      _cachedResponse?.latestVersion;

  @override
  Future<void> initialize() async {}

  @override
  bool isVersionLower(String v1, String v2) => v1.compareTo(v2) < 0;

  @override
  String get currentVersion => '1.0.0';

  @override
  PlatformType get currentPlatform => PlatformType.android;

  @override
  CheckAppVersionResponse? get cachedResponse => _cachedResponse;

  @override
  DateTime? get lastCheckedAt => _lastCheckedAt;
}

CheckAppVersionResponse buildOptionalUpdate({bool mandatory = false}) {
  return CheckAppVersionResponse(
    hasUpdate: true,
    isMandatory: mandatory,
    latestVersion: AppVersionInfo(
      id: 'v2',
      versionName: '1.1.0',
      platform: PlatformType.android,
      description: '테스트 업데이트',
      isMandatory: mandatory,
      filePath: '/tmp',
      fileName: 'app.apk',
      isActive: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
      downloadUrl: 'https://example.com/app.apk',
    ),
  );
}

void main() {
  group('AppVersionNotifier', () {
    test('hydrateFromCache loads cached response', () {
      final fakeService = FakeAppVersionService();
      final cached = buildOptionalUpdate();
      final timestamp = DateTime(2024, 12, 24);
      fakeService.setCached(cached, timestamp);

      final notifier = AppVersionNotifier(service: fakeService);
      notifier.hydrateFromCache();

      expect(notifier.state.versionInfo, equals(cached));
      expect(notifier.state.lastCheckedAt, equals(timestamp));
    });

    test('checkVersion updates state and resets dismissal', () async {
      final response = buildOptionalUpdate();
      final fakeService = FakeAppVersionService(responses: [response]);

      final notifier = AppVersionNotifier(service: fakeService);
      notifier.dismissOptionalUpdate();
      await notifier.checkVersion(force: true);

      expect(notifier.state.versionInfo, equals(response));
      expect(notifier.state.optionalUpdateDismissed, isFalse);
      expect(notifier.state.hasOptionalUpdate, isTrue);
    });

    test('dismissOptionalUpdate marks optional updates as handled', () async {
      final response = buildOptionalUpdate();
      final fakeService = FakeAppVersionService(responses: [response]);
      final notifier = AppVersionNotifier(service: fakeService);

      await notifier.checkVersion(force: true);
      notifier.dismissOptionalUpdate();

      expect(notifier.state.optionalUpdateDismissed, isTrue);
      expect(notifier.state.hasOptionalUpdate, isFalse);
    });
  });
}
