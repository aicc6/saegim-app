# 새김 앱 인증 시스템 통합 가이드

## 📋 개요

새김 프로젝트의 웹사이트와 Flutter 앱 간의 인증 시스템 통합 방식에 대한 상세 가이드입니다.

---

## 🌐 서비스 구조

### 전체 아키텍처
```
웹사이트 (saegim.aicc-project.com) -----> API 서버 (saegim-api.aicc-project.com) <----- Flutter 앱
                                      ↓
                                 통합 데이터베이스
```

### 서비스 관계
- **웹사이트**: `https://saegim.aicc-project.com` (기존 운영 중)
- **API 서버**: `https://saegim-api.aicc-project.com` (공통 백엔드)
- **Flutter 앱**: 새로 개발 중인 모바일 앱
- **데이터베이스**: 웹과 앱이 공유하는 단일 사용자 DB

---

## 🔐 인증 방식 차이점

### 웹 브라우저 인증
```javascript
// HttpOnly 쿠키 기반 인증
Set-Cookie: auth_token=jwt_token; HttpOnly; Secure

// 자동 쿠키 전송
fetch('/api/user', {
  credentials: 'include'
})
```

**특징**:
- HttpOnly 쿠키 사용
- XSS 공격 방어
- 브라우저가 자동으로 쿠키 관리
- 세션 기반 또는 JWT를 쿠키에 저장

### Flutter 앱 인증
```dart
// JWT Bearer 토큰 기반 인증
headers: {
  'Authorization': 'Bearer $jwt_token'
}
```

**특징**:
- Authorization 헤더 방식
- JWT Bearer 토큰 사용
- flutter_secure_storage에 토큰 저장
- 수동 토큰 관리 필요

---

## 📊 API 스펙 분석

### 회원가입 API
```http
POST /api/auth/signup
Content-Type: application/json

{
  "email": "user@example.com",     // 필수, 이메일 형식
  "password": "password123",       // 필수
  "nickname": "사용자닉네임"        // 필수
}
```

**응답**: `SignupResponse` (user_id, email, nickname, message)

### 로그인 API
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",     // 필수, 이메일 형식
  "password": "password123"        // 필수
}
```

**응답**: `LoginResponse` (JWT 토큰 포함)

### 기타 인증 API
- **로그아웃**: `/api/auth/logout`
- **토큰 갱신**: `/api/auth/refresh`
- **비밀번호 재설정**: 지원
- **이메일 변경**: 지원
- **계정 복구**: 지원
- **구글 OAuth**: `/api/auth/google/login`, `/api/auth/google/callback`

### 인증 방식
- **보안 스키마**: bearerAuth
- **헤더 형식**: `Authorization: Bearer {token}`
- **토큰 타입**: JWT

---

## 🔄 양방향 호환성

### 크로스 플랫폼 사용자 시스템
```
          통합 사용자 계정 (DB)
         /                    \
    웹사이트 ←→ API 서버 ←→ Flutter 앱

어디서 가입하든 → 어디서든 로그인 가능!
```

### 호환 시나리오

#### 1. 웹 → 앱
```
1. 웹사이트에서 회원가입
2. 사용자 정보가 공통 DB에 저장
3. Flutter 앱에서 동일한 이메일/비밀번호로 로그인 가능 ✅
```

#### 2. 앱 → 웹
```
1. Flutter 앱에서 회원가입 (nickname 포함)
2. 사용자 정보가 공통 DB에 저장
3. 웹사이트에서 동일한 이메일/비밀번호로 로그인 가능 ✅
```

#### 3. 구글 소셜 로그인
- 웹에서 구글 로그인 → 앱에서도 동일 계정 사용 가능
- 앱에서 구글 로그인 → 웹에서도 동일 계정 사용 가능

---

## 🛠️ Flutter 앱 구현 방안

### 필요한 패키지
```yaml
dependencies:
  dio: ^5.3.2                    # HTTP 클라이언트
  flutter_secure_storage: ^9.0.0 # 토큰 보안 저장

dev_dependencies:
  dio_cookie_manager: ^3.1.1     # 쿠키 관리 (필요시)
  cookie_jar: ^4.0.8            # 쿠키 저장소 (필요시)
```

### 인증 방식 선택

#### 방법 1: JWT Bearer 토큰 (권장)
```dart
// 로그인 후 토큰 저장
final storage = FlutterSecureStorage();
await storage.write(key: 'auth_token', value: jwtToken);

// API 요청시 헤더 추가
final dio = Dio();
dio.options.headers['Authorization'] = 'Bearer $token';
```

#### 방법 2: 쿠키 매니저 (웹 호환성 최대화)
```dart
// 웹과 동일한 쿠키 방식 사용
final dio = Dio();
dio.interceptors.add(CookieManager(CookieJar()));
```

---

## 📱 현재 Flutter 앱 상태

### 기존 구조 분석
- **로그인 페이지**: 완성 (`login_page.dart`)
- **회원가입 페이지**: 준비 중 상태 (`signup_page.dart`)
- **AuthProvider**: 기본 구조 완성, API 연동 TODO 상태
- **라우팅**: 회원가입 경로 설정됨

### 구현 필요 사항
1. **HTTP 클라이언트 설정** (dio + JWT 인증)
2. **회원가입 UI 구현** (nickname 필드 추가)
3. **실제 API 연동** (AuthProvider 내 TODO 구현)
4. **토큰 저장/관리** (flutter_secure_storage)
5. **에러 처리 및 유효성 검사**

---

## 🎯 구현 우선순위

### Phase 1: 기본 인증
1. HTTP 클라이언트 설정
2. 회원가입 UI 완성
3. 로그인/회원가입 API 연동
4. 토큰 저장 및 자동 로그인

### Phase 2: 고급 기능
1. 토큰 갱신 로직
2. 비밀번호 찾기/재설정
3. 구글 소셜 로그인
4. 에러 처리 강화

### Phase 3: 최적화
1. API 요청 인터셉터
2. 오프라인 모드 지원
3. 보안 강화
4. 성능 최적화

---

## 🔍 검증 방법

### 양방향 호환성 테스트
1. **앱에서 회원가입** → **웹에서 로그인** 테스트
2. **웹에서 회원가입** → **앱에서 로그인** 테스트
3. **구글 로그인** 양방향 테스트
4. **토큰 갱신** 및 **세션 관리** 테스트

### API 연동 테스트
```bash
# 회원가입 테스트
curl -X POST https://saegim-api.aicc-project.com/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123","nickname":"테스터"}'

# 로그인 테스트
curl -X POST https://saegim-api.aicc-project.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

---

## 📚 참고 자료

- **API 문서**: https://saegim-api.aicc-project.com/docs
- **OpenAPI 스펙**: https://saegim-api.aicc-project.com/openapi.json
- **웹사이트**: https://saegim.aicc-project.com
- **Flutter 인증 가이드**: [공식 문서](https://docs.flutter.dev/cookbook/networking/authenticated-requests)

---

*이 문서는 새김 프로젝트의 크로스 플랫폼 인증 시스템 이해를 위한 종합 가이드입니다.*