import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:saegim/core/services/fcm_message_service.dart';
import 'package:saegim/shared/widgets/common_app_bar.dart';

class FcmDebugPage extends StatefulWidget {
  const FcmDebugPage({super.key});

  @override
  State<FcmDebugPage> createState() => _FcmDebugPageState();
}

class _FcmDebugPageState extends State<FcmDebugPage> {
  String? _fcmToken;
  NotificationSettings? _notificationSettings;
  bool _isLoading = true;
  final List<String> _notificationLogs = [];

  // 서버 등록 상태 관련
  Map<String, dynamic>? _tokenStatus;
  bool _isRegistrationLoading = false;

  // 서비스 인스턴스
  final FCMMessageService _fcmService = FCMMessageService.instance;

  @override
  void initState() {
    super.initState();
    _initializeFcm();
    _setupMessageListener();
    _checkTokenRegistrationStatus();
  }

  Future<void> _initializeFcm() async {
    try {
      // FCM 토큰 획득
      final token = await FirebaseMessaging.instance.getToken();

      // 알림 권한 상태 확인
      final settings = await FirebaseMessaging.instance.getNotificationSettings();

      setState(() {
        _fcmToken = token;
        _notificationSettings = settings;
        _isLoading = false;
      });

      _addLog('FCM 초기화 완료');
      if (token != null) {
        _addLog('FCM 토큰 획득 성공');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _addLog('FCM 초기화 실패: $e');
    }
  }

  void _setupMessageListener() {
    // 포그라운드 메시지 수신 리스너
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _addLog('포그라운드 메시지 수신: ${message.notification?.title ?? "제목 없음"}');
    });

    // 백그라운드에서 앱 열기 리스너
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _addLog('백그라운드에서 앱 열기: ${message.notification?.title ?? "제목 없음"}');
    });
  }

  void _addLog(String message) {
    setState(() {
      _notificationLogs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
      if (_notificationLogs.length > 20) {
        _notificationLogs.removeLast();
      }
    });
  }

  Future<void> _copyTokenToClipboard() async {
    if (_fcmToken != null) {
      await Clipboard.setData(ClipboardData(text: _fcmToken!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('FCM 토큰이 클립보드에 복사되었습니다'),
            backgroundColor: Color(0xFFB2C5B8),
          ),
        );
      }
    }
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    setState(() {
      _notificationSettings = settings;
    });

    _addLog('알림 권한 요청 완료: ${settings.authorizationStatus.name}');
  }

  Future<void> _refreshFcmData() async {
    setState(() {
      _isLoading = true;
    });
    await _initializeFcm();
    await _checkTokenRegistrationStatus();
  }

  /// 토큰 서버 등록 상태 확인
  Future<void> _checkTokenRegistrationStatus() async {
    try {
      final status = await _fcmService.checkTokenStatus();

      setState(() {
        _tokenStatus = status;
      });

      if (status != null) {
        _addLog('서버 등록 상태: 등록됨 (${status['device_type'] ?? 'unknown'})');
      } else {
        _addLog('서버 등록 상태: 미등록');
      }
    } catch (e) {
      _addLog('서버 등록 상태 확인 실패: $e');
    }
  }

  /// 토큰을 서버에 등록
  Future<void> _registerTokenToServer() async {
    if (_fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('FCM 토큰이 없습니다. 먼저 토큰을 생성해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isRegistrationLoading = true;
    });

    try {
      final success = await _fcmService.registerTokenOnLogin();

      if (success) {
        _addLog('서버 등록 성공');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('FCM 토큰이 서버에 등록되었습니다'),
              backgroundColor: Color(0xFFB2C5B8),
            ),
          );
        }
        // 등록 후 상태 다시 확인
        await _checkTokenRegistrationStatus();
      } else {
        _addLog('서버 등록 실패');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('FCM 토큰 서버 등록에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _addLog('서버 등록 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRegistrationLoading = false;
      });
    }
  }

  /// 토큰을 서버에서 해제
  Future<void> _unregisterTokenFromServer() async {
    setState(() {
      _isRegistrationLoading = true;
    });

    try {
      final success = await _fcmService.deactivateTokenOnLogout();

      if (success) {
        _addLog('서버 해제 성공');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('FCM 토큰이 서버에서 해제되었습니다'),
              backgroundColor: Color(0xFFB2C5B8),
            ),
          );
        }
        // 해제 후 상태 다시 확인
        await _checkTokenRegistrationStatus();
      } else {
        _addLog('서버 해제 실패');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('FCM 토큰 서버 해제에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      _addLog('서버 해제 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isRegistrationLoading = false;
      });
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    Color? valueColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFB2C5B8).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFFB2C5B8),
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E3A59),
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: valueColor ?? Colors.grey[600],
            fontFamily: 'monospace',
          ),
        ),
        trailing: onTap != null
            ? const Icon(Icons.copy, color: Color(0xFFB2C5B8), size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }

  String _getAuthorizationStatusText(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return '허용됨';
      case AuthorizationStatus.denied:
        return '거부됨';
      case AuthorizationStatus.notDetermined:
        return '결정되지 않음';
      case AuthorizationStatus.provisional:
        return '임시 허용';
    }
  }

  Color _getAuthorizationStatusColor(AuthorizationStatus status) {
    switch (status) {
      case AuthorizationStatus.authorized:
        return Colors.green;
      case AuthorizationStatus.denied:
        return Colors.red;
      case AuthorizationStatus.notDetermined:
        return Colors.orange;
      case AuthorizationStatus.provisional:
        return Colors.blue;
    }
  }

  String _getDeviceInfoString(Map<String, dynamic> deviceInfo) {
    // 주요 디바이스 정보를 문자열로 포맷팅
    final model = deviceInfo['model'] ?? deviceInfo['device'] ?? 'unknown';
    final version = deviceInfo['version'] ?? deviceInfo['release'] ?? 'unknown';
    final brand = deviceInfo['brand'] ?? deviceInfo['manufacturer'] ?? '';

    if (brand.isNotEmpty && brand != model) {
      return '$brand $model (v$version)';
    } else {
      return '$model (v$version)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB2C5B8)),
            )
          : RefreshIndicator(
              color: const Color(0xFFB2C5B8),
              onRefresh: _refreshFcmData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // 페이지 제목
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.bug_report, size: 60, color: Color(0xFFB2C5B8)),
                        SizedBox(height: 16),
                        Text(
                          'FCM 디버깅',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E3A59),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Firebase Cloud Messaging 상태 및 로그',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // FCM 토큰 정보
                  const Text(
                    'FCM 토큰',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3A59),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    title: 'FCM Token',
                    value: _fcmToken ?? '토큰을 가져올 수 없습니다',
                    icon: Icons.key,
                    onTap: _fcmToken != null ? _copyTokenToClipboard : null,
                  ),

                  const SizedBox(height: 24),

                  // 알림 권한 상태
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '알림 권한 상태',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3A59),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _requestPermission,
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('권한 요청'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB2C5B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_notificationSettings != null) ...[
                    _buildInfoCard(
                      title: '알림 권한',
                      value: _getAuthorizationStatusText(_notificationSettings!.authorizationStatus),
                      icon: Icons.notifications,
                      valueColor: _getAuthorizationStatusColor(_notificationSettings!.authorizationStatus),
                    ),
                    _buildInfoCard(
                      title: '알림음',
                      value: _notificationSettings!.sound == AppleNotificationSetting.enabled ? '허용됨' : '거부됨',
                      icon: Icons.volume_up,
                      valueColor: _notificationSettings!.sound == AppleNotificationSetting.enabled ? Colors.green : Colors.red,
                    ),
                    _buildInfoCard(
                      title: '배지',
                      value: _notificationSettings!.badge == AppleNotificationSetting.enabled ? '허용됨' : '거부됨',
                      icon: Icons.circle_notifications,
                      valueColor: _notificationSettings!.badge == AppleNotificationSetting.enabled ? Colors.green : Colors.red,
                    ),
                    _buildInfoCard(
                      title: '알림 표시',
                      value: _notificationSettings!.alert == AppleNotificationSetting.enabled ? '허용됨' : '거부됨',
                      icon: Icons.notification_important,
                      valueColor: _notificationSettings!.alert == AppleNotificationSetting.enabled ? Colors.green : Colors.red,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 서버 등록 상태
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '서버 등록 상태',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E3A59),
                        ),
                      ),
                      if (_isRegistrationLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFB2C5B8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    title: '등록 상태',
                    value: _tokenStatus != null ? '등록됨' : '미등록',
                    icon: _tokenStatus != null ? Icons.check_circle : Icons.cancel,
                    valueColor: _tokenStatus != null ? Colors.green : Colors.red,
                  ),

                  if (_tokenStatus != null) ...[
                    _buildInfoCard(
                      title: '디바이스 타입',
                      value: _tokenStatus!['device_type'] ?? 'unknown',
                      icon: Icons.phone_android,
                    ),
                    _buildInfoCard(
                      title: '등록 시간',
                      value: _tokenStatus!['created_at'] ?? 'unknown',
                      icon: Icons.schedule,
                    ),
                    if (_tokenStatus!['device_info'] != null)
                      _buildInfoCard(
                        title: '디바이스 정보',
                        value: _getDeviceInfoString(_tokenStatus!['device_info']),
                        icon: Icons.info,
                      ),
                  ],

                  const SizedBox(height: 16),

                  // 서버 등록/해제 버튼
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isRegistrationLoading ? null : _registerTokenToServer,
                          icon: const Icon(Icons.cloud_upload),
                          label: const Text('서버 등록'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB2C5B8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isRegistrationLoading ? null : _unregisterTokenFromServer,
                          icon: const Icon(Icons.cloud_off),
                          label: const Text('서버 해제'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 알림 로그
                  const Text(
                    '알림 로그',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E3A59),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.history, color: Color(0xFFB2C5B8), size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                '최근 로그',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2E3A59),
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _notificationLogs.clear();
                                  });
                                },
                                child: const Text(
                                  '지우기',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: _notificationLogs.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                    '아직 로그가 없습니다',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: _notificationLogs.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                      child: Text(
                                        _notificationLogs[index],
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          color: Color(0xFF2E3A59),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}