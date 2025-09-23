import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// FCM 디버깅 및 테스트를 위한 화면
class FCMDebugScreen extends StatefulWidget {
  const FCMDebugScreen({super.key});

  @override
  State<FCMDebugScreen> createState() => _FCMDebugScreenState();
}

class _FCMDebugScreenState extends State<FCMDebugScreen> {
  String? _fcmToken;
  NotificationSettings? _notificationSettings;

  bool _isLoading = false;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initializeFCMDebug();
  }

  Future<void> _initializeFCMDebug() async {
    setState(() => _isLoading = true);

    try {
      await _checkFCMToken();
      await _checkNotificationPermissions();
      await _checkAPNSToken();
      await _registerMessageHandlers();
    } catch (e) {
      _addLog('초기화 오류: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkFCMToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      setState(() => _fcmToken = token);
      _addLog('FCM 토큰 생성 완료: ${token?.substring(0, 20)}...');
      AppLogger.debug('FCM Token: $token', 'FCMDebug');
    } catch (e) {
      _addLog('FCM 토큰 가져오기 실패: $e');
    }
  }

  Future<void> _checkNotificationPermissions() async {
    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      setState(() => _notificationSettings = settings);
      _addLog('알림 권한 상태: ${settings.authorizationStatus.name}');
    } catch (e) {
      _addLog('알림 권한 확인 실패: $e');
    }
  }

  Future<void> _checkAPNSToken() async {
    try {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      // APNS token received
      if (apnsToken != null) {
        _addLog('APNS 토큰 확인 완료: ${apnsToken.substring(0, 20)}...');
      } else {
        _addLog('APNS 토큰이 없습니다 (Android에서는 정상)');
      }
    } catch (e) {
      _addLog('APNS 토큰 확인 실패: $e');
    }
  }

  Future<void> _registerMessageHandlers() async {
    // 포그라운드 메시지 수신
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _addLog('포그라운드 메시지 수신: ${message.notification?.title ?? message.messageId}');
      _showMessageDialog(message, '포그라운드 메시지');
    });

    // 백그라운드에서 앱 열기
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _addLog('백그라운드에서 앱 열기: ${message.notification?.title ?? message.messageId}');
      _showMessageDialog(message, '백그라운드 메시지');
    });

    // 앱 종료 상태에서 메시지 확인
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _addLog('앱 종료 상태에서 메시지로 시작: ${initialMessage.notification?.title ?? initialMessage.messageId}');
    }

    _addLog('메시지 핸들러 등록 완료');
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
    });
    AppLogger.info(message, 'FCMDebug');
  }

  void _showMessageDialog(RemoteMessage message, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$type 수신'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('제목: ${message.notification?.title ?? "없음"}'),
            Text('내용: ${message.notification?.body ?? "없음"}'),
            Text('데이터: ${message.data}'),
            Text('메시지 ID: ${message.messageId ?? "없음"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      setState(() => _notificationSettings = settings);
      _addLog('권한 요청 완료: ${settings.authorizationStatus.name}');
    } catch (e) {
      _addLog('권한 요청 실패: $e');
    }
  }

  Future<void> _refreshToken() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseMessaging.instance.deleteToken();
      await Future.delayed(const Duration(seconds: 1));
      await _checkFCMToken();
      _addLog('토큰 갱신 완료');
    } catch (e) {
      _addLog('토큰 갱신 실패: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyTokenToClipboard() {
    if (_fcmToken != null) {
      Clipboard.setData(ClipboardData(text: _fcmToken!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('FCM 토큰이 클립보드에 복사되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM 디버깅'),
        backgroundColor: Colors.blue[100],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 16),
                  _buildTokenCard(),
                  const SizedBox(height: 16),
                  _buildPermissionCard(),
                  const SizedBox(height: 16),
                  _buildActionsCard(),
                  const SizedBox(height: 16),
                  _buildLogsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FCM 상태',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _fcmToken != null ? Icons.check_circle : Icons.error,
                  color: _fcmToken != null ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(_fcmToken != null ? 'FCM 토큰 생성됨' : 'FCM 토큰 없음'),
              ],
            ),
            Row(
              children: [
                Icon(
                  _notificationSettings?.authorizationStatus == AuthorizationStatus.authorized
                      ? Icons.check_circle
                      : Icons.error,
                  color: _notificationSettings?.authorizationStatus == AuthorizationStatus.authorized
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(_notificationSettings?.authorizationStatus == AuthorizationStatus.authorized
                    ? '알림 권한 허용됨'
                    : '알림 권한 필요'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'FCM 토큰',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (_fcmToken != null)
                  IconButton(
                    onPressed: _copyTokenToClipboard,
                    icon: const Icon(Icons.copy),
                    tooltip: '토큰 복사',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _fcmToken ?? '토큰이 생성되지 않았습니다',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: _fcmToken != null ? Colors.black : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '알림 권한',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_notificationSettings != null) ...[
              _buildPermissionRow('권한 상태', _notificationSettings!.authorizationStatus.name),
              _buildPermissionRow('알림', _notificationSettings!.alert.name),
              _buildPermissionRow('배지', _notificationSettings!.badge.name),
              _buildPermissionRow('소리', _notificationSettings!.sound.name),
            ] else
              const Text('권한 정보를 가져오는 중...'),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              color: value == 'authorized' || value == 'enabled' ? Colors.green : Colors.orange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '액션',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _requestPermissions,
                  child: const Text('권한 요청'),
                ),
                ElevatedButton(
                  onPressed: _refreshToken,
                  child: const Text('토큰 갱신'),
                ),
                ElevatedButton(
                  onPressed: _initializeFCMDebug,
                  child: const Text('상태 새로고침'),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => _logs.clear()),
                  child: const Text('로그 지우기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '실시간 로그',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Text(
                    _logs[index],
                    style: const TextStyle(
                      color: Colors.green,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}