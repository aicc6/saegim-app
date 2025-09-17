import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:saegim/shared/utils/app_logger.dart';

/// 보안 강화된 쿠키 저장소
///
/// CookieJar를 구현하여 모든 쿠키 관리 기능을 제공하며,
/// flutter_secure_storage를 사용하여 쿠키를 암호화하여 저장합니다.
class SecureCookieJar implements CookieJar {
  static const String _storageKey = 'secure_cookies_v1';
  static const String _encryptionKeyStorage = 'cookie_encryption_key';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  String? _encryptionKey;
  Map<String, List<SerializableCookie>> _cookieStorage = {};
  bool _isInitialized = false;

  @override
  bool get ignoreExpires => false;

  /// 초기화 메서드
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 암호화 키 초기화
      await _initEncryptionKey();

      // 저장된 쿠키 로드
      await _loadCookiesFromStorage();

      _isInitialized = true;
      AppLogger.info('SecureCookieJar 초기화 완료');
    } catch (e) {
      AppLogger.error('SecureCookieJar 초기화 실패', error: e);
      _isInitialized = true; // 실패해도 초기화 완료로 처리
    }
  }

  /// 암호화 키 초기화
  Future<void> _initEncryptionKey() async {
    _encryptionKey = await _secureStorage.read(key: _encryptionKeyStorage);

    if (_encryptionKey == null) {
      // 새로운 암호화 키 생성 (32바이트)
      final keyBytes = List<int>.generate(
        32,
        (i) => DateTime.now().millisecondsSinceEpoch.hashCode + i,
      );
      _encryptionKey = sha256.convert(keyBytes).toString();

      await _secureStorage.write(
        key: _encryptionKeyStorage,
        value: _encryptionKey!,
      );

      AppLogger.info('새로운 쿠키 암호화 키 생성');
    }
  }

  /// 데이터 암호화 (AES 대신 간단한 XOR 사용)
  String _encryptData(String data) {
    if (_encryptionKey == null) throw StateError('암호화 키가 초기화되지 않았습니다');

    final dataBytes = utf8.encode(data);
    final keyBytes = utf8.encode(_encryptionKey!);
    final encryptedBytes = <int>[];

    for (int i = 0; i < dataBytes.length; i++) {
      encryptedBytes.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64.encode(encryptedBytes);
  }

  /// 데이터 복호화
  String _decryptData(String encryptedData) {
    if (_encryptionKey == null) throw StateError('암호화 키가 초기화되지 않았습니다');

    try {
      final encryptedBytes = base64.decode(encryptedData);
      final keyBytes = utf8.encode(_encryptionKey!);
      final decryptedBytes = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }

      return utf8.decode(decryptedBytes);
    } catch (e) {
      AppLogger.error('쿠키 복호화 실패', error: e);
      return '{}';
    }
  }

  /// 저장소에서 쿠키 로드
  Future<void> _loadCookiesFromStorage() async {
    try {
      final encryptedData = await _secureStorage.read(key: _storageKey);
      if (encryptedData == null) {
        _cookieStorage = {};
        return;
      }

      final decryptedData = _decryptData(encryptedData);
      final Map<String, dynamic> jsonData = jsonDecode(decryptedData);

      _cookieStorage = {};
      jsonData.forEach((domain, cookies) {
        if (cookies is List) {
          _cookieStorage[domain] = cookies
              .map((c) => SerializableCookie.fromJson(c))
              .toList();
        }
      });

      AppLogger.debug('쿠키 로드 완료: ${_cookieStorage.length}개 도메인');
    } catch (e) {
      AppLogger.error('쿠키 로드 실패', error: e);
      _cookieStorage = {};
    }
  }

  /// 저장소에 쿠키 저장
  Future<void> _saveCookiesToStorage() async {
    try {
      final Map<String, dynamic> jsonData = {};
      _cookieStorage.forEach((domain, cookies) {
        jsonData[domain] = cookies.map((c) => c.toJson()).toList();
      });

      final dataString = jsonEncode(jsonData);
      final encryptedData = _encryptData(dataString);

      await _secureStorage.write(key: _storageKey, value: encryptedData);
      AppLogger.debug('쿠키 저장 완료: ${_cookieStorage.length}개 도메인');
    } catch (e) {
      AppLogger.error('쿠키 저장 실패', error: e);
    }
  }

  @override
  Future<List<Cookie>> loadForRequest(Uri uri) async {
    if (!_isInitialized) {
      throw StateError('SecureCookieJar not initialized. Call init() first.');
    }

    final String domain = uri.host;
    final String path = uri.path.isEmpty ? '/' : uri.path;
    final List<Cookie> matchingCookies = [];

    _cookieStorage.forEach((key, cookies) {
      for (final cookie in cookies) {
        // 도메인 매칭 확인 (null 체크 추가)
        final cookieDomain = cookie.domain ?? '';
        if (!_isDomainMatch(domain, cookieDomain)) {
          continue;
        }

        // 경로 매칭 확인 (null 체크 추가)
        final cookiePath = cookie.path ?? '/';
        if (!_isPathMatch(path, cookiePath)) {
          continue;
        }

        // 만료 확인
        if (!ignoreExpires &&
            cookie.expires != null &&
            cookie.expires!.isBefore(DateTime.now())) {
          continue;
        }

        // Secure 쿠키는 HTTPS에서만
        if (cookie.secure && uri.scheme != 'https') {
          continue;
        }

        matchingCookies.add(
          Cookie(cookie.name, cookie.value)
            ..domain = cookie.domain
            ..path = cookie.path
            ..expires = cookie.expires
            ..secure = cookie.secure
            ..httpOnly = cookie.httpOnly,
        );
      }
    });

    return matchingCookies;
  }

  @override
  Future<void> saveFromResponse(Uri uri, List<Cookie> cookies) async {
    if (!_isInitialized) {
      throw StateError('SecureCookieJar not initialized. Call init() first.');
    }

    final String domain = uri.host;
    final String path = uri.path.isEmpty ? '/' : uri.path;

    for (final cookie in cookies) {
      // 쿠키 도메인 및 경로 설정
      String cookieDomain = cookie.domain ?? domain;
      String cookiePath = cookie.path ?? path;

      // 도메인이 점으로 시작하지 않으면 점 추가 (subdomain 매칭을 위해)
      if (!cookieDomain.startsWith('.') && cookieDomain.contains('.')) {
        cookieDomain = '.$cookieDomain';
      }

      final key = '$cookieDomain|$cookiePath';
      final serializableCookie = SerializableCookie.fromCookie(
        cookie,
        cookieDomain,
      );

      // 기존 쿠키 업데이트 또는 새 쿠키 추가
      final existingCookies = _cookieStorage[key] ?? [];
      final existingIndex = existingCookies.indexWhere(
        (c) => c.name == cookie.name,
      );

      if (existingIndex >= 0) {
        existingCookies[existingIndex] = serializableCookie;
      } else {
        existingCookies.add(serializableCookie);
      }

      _cookieStorage[key] = existingCookies;
    }

    // 만료된 쿠키 정리
    _cleanExpiredCookies();

    // 스토리지에 저장
    await _saveCookiesToStorage();
  }

  @override
  Future<void> delete(Uri uri, [bool withDomainSharedCookie = false]) async {
    if (!_isInitialized) {
      throw StateError('SecureCookieJar not initialized. Call init() first.');
    }

    final String domain = uri.host;
    final String path = uri.path.isEmpty ? '/' : uri.path;

    _cookieStorage.removeWhere((key, cookies) {
      final parts = key.split('|');
      if (parts.length != 2) return false;

      final cookieDomain = parts[0];
      final cookiePath = parts[1];

      if (withDomainSharedCookie) {
        return _isDomainMatch(domain, cookieDomain);
      } else {
        return cookieDomain == domain && _isPathMatch(path, cookiePath);
      }
    });

    await _saveCookiesToStorage();
  }

  @override
  Future<void> deleteAll() async {
    if (!_isInitialized) {
      throw StateError('SecureCookieJar not initialized. Call init() first.');
    }

    _cookieStorage.clear();
    await _secureStorage.delete(key: _storageKey);
  }

  /// 만료된 쿠키 정리
  void _cleanExpiredCookies() {
    final now = DateTime.now();

    _cookieStorage.forEach((domain, cookies) {
      cookies.removeWhere((cookie) {
        return cookie.expires != null && now.isAfter(cookie.expires!);
      });
    });

    // 빈 도메인 제거
    _cookieStorage.removeWhere((domain, cookies) => cookies.isEmpty);
  }

  /// 도메인 매칭 확인
  bool _isDomainMatch(String requestDomain, String cookieDomain) {
    if (cookieDomain.startsWith('.')) {
      // .example.com 형태의 도메인
      return requestDomain.endsWith(cookieDomain.substring(1)) ||
          requestDomain == cookieDomain.substring(1);
    } else {
      // 정확한 도메인 매칭
      return requestDomain == cookieDomain;
    }
  }

  /// 경로 매칭 확인
  bool _isPathMatch(String requestPath, String cookiePath) {
    return requestPath.startsWith(cookiePath);
  }
}

/// 직렬화 가능한 쿠키 클래스
class SerializableCookie {
  final String name;
  final String value;
  final String? domain;
  final String? path;
  final DateTime? expires;
  final bool secure;
  final bool httpOnly;
  final SameSite? sameSite;

  SerializableCookie({
    required this.name,
    required this.value,
    this.domain,
    this.path,
    this.expires,
    this.secure = false,
    this.httpOnly = false,
    this.sameSite,
  });

  factory SerializableCookie.fromCookie(Cookie cookie, String defaultDomain) {
    return SerializableCookie(
      name: cookie.name,
      value: cookie.value,
      domain: cookie.domain ?? defaultDomain,
      path: cookie.path ?? '/',
      expires: cookie.expires,
      secure: cookie.secure,
      httpOnly: cookie.httpOnly,
      sameSite: cookie.sameSite,
    );
  }

  factory SerializableCookie.fromJson(Map<String, dynamic> json) {
    return SerializableCookie(
      name: json['name'],
      value: json['value'],
      domain: json['domain'],
      path: json['path'],
      expires: json['expires'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['expires'])
          : null,
      secure: json['secure'] ?? false,
      httpOnly: json['httpOnly'] ?? false,
      sameSite: json['sameSite'] != null
          ? SameSite.values.firstWhere(
              (e) => e.toString() == json['sameSite'],
              orElse: () => SameSite.lax,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'domain': domain,
      'path': path,
      'expires': expires?.millisecondsSinceEpoch,
      'secure': secure,
      'httpOnly': httpOnly,
      'sameSite': sameSite?.toString(),
    };
  }

  Cookie toCookie() {
    final cookie = Cookie(name, value);
    cookie.domain = domain;
    cookie.path = path;
    cookie.expires = expires;
    cookie.secure = secure;
    cookie.httpOnly = httpOnly;
    cookie.sameSite = sameSite;
    return cookie;
  }
}
