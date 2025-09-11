import 'package:flutter/material.dart';

/// 인증 상태를 관리하는 Provider
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userId;
  String? _userEmail;
  bool _isInitialized = false;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  bool get isInitialized => _isInitialized;

  /// 안전한 초기화 메서드 (앱 시작 후 명시적으로 호출)
  Future<void> initialize() async {
    if (_isInitialized) return; // 중복 초기화 방지
    
    await checkAuthStatus();
    _isInitialized = true;
  }

  /// 로그인 상태 확인 (내부적으로만 호출)
  Future<void> checkAuthStatus() async {
    // notifyListeners() 호출 전에 mounted 체크는 불가하므로 
    // 상태만 변경하고 마지막에 한 번만 notify
    _isLoading = true;
    
    try {
      // TODO: 실제 인증 상태 확인 로직 구현
      // SharedPreferences나 Secure Storage에서 토큰 확인
      await Future.delayed(const Duration(seconds: 1)); // 임시 로딩 시뮬레이션
      
      // 임시로 false로 설정 (실제로는 저장된 토큰을 확인)
      _isAuthenticated = false;
    } catch (e) {
      _isAuthenticated = false;
    }
    
    _isLoading = false;
    notifyListeners(); // 마지막에 한 번만 호출
  }

  /// 로그인
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // TODO: 실제 로그인 API 호출
      await Future.delayed(const Duration(seconds: 2)); // 임시 로딩 시뮬레이션
      
      // 임시로 성공으로 처리
      _isAuthenticated = true;
      _userId = 'temp_user_id';
      _userEmail = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 회원가입
  Future<bool> signup(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // TODO: 실제 회원가입 API 호출
      await Future.delayed(const Duration(seconds: 2)); // 임시 로딩 시뮬레이션
      
      // 임시로 성공으로 처리
      _isAuthenticated = true;
      _userId = 'temp_user_id';
      _userEmail = email;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 로그아웃
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // TODO: 실제 로그아웃 처리 (토큰 삭제 등)
      await Future.delayed(const Duration(seconds: 1));
      
      _isAuthenticated = false;
      _userId = null;
      _userEmail = null;
    } catch (e) {
      // 에러가 발생해도 로컬 상태는 초기화
      _isAuthenticated = false;
      _userId = null;
      _userEmail = null;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// 비밀번호 찾기
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // TODO: 실제 비밀번호 찾기 API 호출
      await Future.delayed(const Duration(seconds: 2));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 계정 복구
  Future<bool> restoreAccount(String email) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // TODO: 실제 계정 복구 API 호출
      await Future.delayed(const Duration(seconds: 2));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}