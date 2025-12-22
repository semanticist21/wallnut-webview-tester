# Network Tab Strategy Reassessment: Eruda vs Wallnut

**Date**: 2025-12-22
**Status**: Deep Architectural Analysis

---

## Executive Summary

기존 "Network 개선 계획"을 재검토한 결과, **Eruda와 Wallnut의 역할 분담이 필요**합니다.

**결론:**
- ✅ **Eruda가 더 잘할 수 있는 것**: CORS/캐싱 분석, 기본 네트워크 모니터링
- ✅ **Wallnut이 고유하게 할 수 있는 것**: 응답 포맷팅, 타이밍 워터폴, 스택 트레이스
- ❌ **피해야 할 것**: Eruda와 완전 중복되는 기능

---

## Part 1: 현재 구조 분석

### Wallnut Network Architecture

**Location**: `Features/Network/`

**세 계층 구조:**

```
NetworkManager (Singleton)
  ├─ NetworkBodyStorage (disk cache)
  │   └─ Request/Response body를 파일로 저장 (메모리 효율)
  ├─ networkManager.requests (in-memory)
  │   └─ 메타데이터 (headers, status, timing)
  └─ JavaScript Hook (fetch/XHR 후킹)
      └─ Browser에서 요청 캡처

NetworkView (UI)
  ├─ networkManager.requests (network tab)
  ├─ resourceManager.resources (resource tab)
  └─ Combined filter (fetch, xhr, img, css, js, etc.)

NetworkDetailView
  ├─ Full request/response body
  ├─ Headers display
  └─ Body rendering (text, JSON)
```

**현재 캡처 방식:**
- `fetch()` / `XMLHttpRequest` → JavaScript Hook으로 캡처
- 이미지, CSS, JS 같은 리소스 → Resource Timing API로 캡처
- Body는 메모리 프리뷰(500자) + 디스크 저장

**현재 기능:**
✅ Request/Response headers
✅ Request/Response body (text, JSON)
✅ Status codes + timing
✅ Filter & search
✅ Preserve log toggle

---

### Eruda Network Architecture

**배포 방식**: WKWebView 내부에 JavaScript 라이브러리 주입

**Eruda의 위치:**
```
WKWebView (페이지)
  ├─ Web Application
  │   ├─ fetch() / XMLHttpRequest
  │   └─ <img>, <script>, <link> 로드
  ├─ Eruda (JS library, 페이지와 동일 context)
  │   ├─ Network tab
  │   │   ├─ fetch/XHR 후킹
  │   │   ├─ Resource Timing API 접근
  │   │   └─ Header 정보 표시
  │   ├─ Storage tab (localStorage/sessionStorage)
  │   ├─ Elements tab (DOM)
  │   └─ Console tab
  └─ Safari Cookie Storage (별도 저장소)
```

**Eruda의 장점:**
✅ JavaScript context 내부 → 모든 정보 접근 가능
✅ CORS 헤더 직접 읽기 가능
✅ Cache-Control, ETag 직접 분석 가능
✅ 응답 바디도 직접 접근 가능

**Eruda의 한계:**
❌ 페이지 바깥에서 분석 불가능
❌ Wallnut Swift code와 통신 어려움
❌ 워터폴, 스택 트레이스 같은 고급 시각화 어려움

---

## Part 2: 기능 비교 매트릭스

### 네트워크 모니터링 기능

| 기능 | Eruda | Wallnut | 추천 |
|------|-------|---------|------|
| **기본 캡처** | ✅ | ✅ | 둘 다 OK |
| **Request 헤더** | ✅ | ✅ | 둘 다 OK |
| **Response 헤더** | ✅ | ✅ | 둘 다 OK |
| **Request 바디** | ✅ | ✅ | 둘 다 OK |
| **Response 바디** | ✅ | ✅ | 둘 다 OK |
| **Status codes** | ✅ | ✅ | 둘 다 OK |
| **Basic timing** | ✅ | ✅ | 둘 다 OK |

### CORS & 보안 분석

| 기능 | Eruda | Wallnut | 추천 |
|------|-------|---------|------|
| **CORS 에러 감지** | ✅ 직접 접근 | ⚠️ JavaScript에서만 | **Eruda** |
| **CORS 헤더 분석** | ✅ | ⚠️ | **Eruda** |
| **Mixed content 경고** | ✅ | ⚠️ | **Eruda** |
| **CORS 해결 제안** | ❌ | 🔄 계획 | **Wallnut 계획 불필요** |

### 캐싱 분석

| 기능 | Eruda | Wallnut | 추천 |
|------|-------|---------|------|
| **Cache-Control** | ✅ 직접 읽기 | ⚠️ String 파싱 | **Eruda** |
| **ETag/Last-Modified** | ✅ | ⚠️ | **Eruda** |
| **Cache hit 감지** | ✅ | ⚠️ | **Eruda** |
| **캐싱 최적화 제안** | ❌ | 🔄 계획 | **Wallnut 계획 불필요** |

### 성능 분석

| 기능 | Eruda | Wallnut | 추천 |
|------|-------|---------|------|
| **Basic timing** | ✅ | ✅ | 둘 다 OK |
| **타이밍 워터폴** | ❌ | ✅ 계획 | **Wallnut** |
| **DNS/TCP/SSL 분석** | ❌ | ✅ 계획 | **Wallnut** |
| **요청 발신자 추적** | ❌ | ✅ 계획 | **Wallnut** |
| **느린 요청 필터** | ❌ | 🔄 계획 | **Wallnut** |
| **병렬/순차 분석** | ❌ | 🔄 계획 | **Wallnut** |

### 고급 기능

| 기능 | Eruda | Wallnut | 추천 |
|------|-------|---------|------|
| **요청 재생(Replay)** | ❌ | 🔄 계획 | **Wallnut** |
| **Export (HAR/JSON/CSV)** | ❌ | 🔄 계획 | **Wallnut** |
| **요청 재정렬/그룹핑** | ⚠️ UI 제약 | ✅ 계획 | **Wallnut** |

---

## Part 3: 재구조화된 전략

### ❌ Wallnut이 피해야 할 기능

**원래 계획에서 제거:**

1. **CORS/Security Analysis** (Priority 3.2)
   - Eruda가 이미 더 잘함
   - CORS 해결 제안은 서버 설정 영역 (클라이언트 도구 범위 밖)

2. **Response Caching Analysis** (Priority 3.1)
   - Eruda가 이미 Cache-Control/ETag 분석
   - 중복 기능

**이유:**
```
Eruda (페이지 내부):
  Cache-Control 헤더 → 직접 읽기 가능

Wallnut (Swift):
  Cache-Control 헤더 → String 파싱으로만 접근

→ Eruda가 훨씬 정확하고 효율적
```

---

### ✅ Wallnut이 집중해야 할 기능

**우선순위 재정렬:**

#### Priority 1: Swift에서만 가능한 기능

**1.1 Response Body Formatting** ✅
- Content-Type 감지
- JSON 포맷팅 + 구문 강조
- 이미지 미리보기
- HTML/XML 포맷팅
- **Wallnut 고유**: Eruda는 작은 UI로 표시 어려움

**1.2 Timing Waterfall** ✅
- DNS/TCP/SSL/Wait/Download 단계별 시각화
- **Wallnut 고유**: Eruda는 단순 duration만 표시

**1.3 Initiator Stack Trace** ✅
- 요청을 시작한 JavaScript 함수 추적
- 파일명, 함수명, 라인 번호 표시
- **Wallnut 고유**: 개발자가 버그 원인 파악 용이

#### Priority 2: UX 개선

**2.1 Advanced Filtering** ✅
- Status code 필터 (200, 404, 5xx)
- Request type 필터 (fetch, xhr, img, script)
- Timing 필터 (>1s slow requests)

**2.2 Export Network Data** ✅
- HAR 포맷
- JSON export
- CSV export
- **용도**: 팀과 공유, 오프라인 분석

**2.3 Request Replay** ✅
- 요청 재현 (modified headers/body)
- API 변경사항 테스트 용이
- **Eruda는 불가능**: 페이지 내부 라이브러리 제약

#### Priority 3: 분석 및 최적화

**3.1 Performance Metrics** ✅
- 가장 큰 요청 (by size)
- 가장 느린 요청 (by duration)
- 병렬 vs 순차 패턴 분석

**3.2 Request Grouping** ✅
- Domain별 그룹핑
- Type별 그룹핑
- 접기/펴기로 공간 절약

**3.3 Mixed Content Warning** (Eruda에서 처리)
- Eruda: CORS + Mixed content 함께 표시
- Wallnut: 기본 표시만

---

## Part 4: 최적의 역할 분담

### Eruda가 처리할 것 (기본 모니터링)

```
사용자가 Settings에서 "Eruda Mode" 활성화
↓
Eruda JavaScript 라이브러리 로드
↓
페이지 우하단 아이콘 표시 (기본 DevTools)

사용자가 Eruda 열기
↓
Eruda Network tab에서:
  ✅ Basic request/response 보기
  ✅ Headers 분석
  ✅ CORS/Mixed content 경고
  ✅ Cache-Control 분석
  ✅ Simple search
```

### Wallnut이 처리할 것 (고급 분석)

```
사용자가 Console/Network DevTools 열기
↓
Wallnut Network View에서:
  ✅ Timing waterfall (Eruda보다 뛰어남)
  ✅ Stack trace (어느 코드가 요청 시작)
  ✅ Advanced filtering (slow requests, etc)
  ✅ Beautiful response formatting
  ✅ Export (HAR/JSON/CSV)
  ✅ Request replay
  ✅ Performance analysis
```

### 사용 시나리오

**시나리오 1: 빠른 디버깅**
```
개발 중 "이 API 응답이 뭐지?" 확인
→ Eruda 열기 (화면의 오른쪽 하단)
→ 빠르게 응답 확인
```

**시나리오 2: 성능 최적화**
```
"왜 이 페이지가 느릴까?"
→ Wallnut DevTools 열기
→ Network tab → Timing waterfall
→ DNS 5초, Download 2초 보이면 원인 파악
→ Request replay로 API 문제 테스트
```

**시나리오 3: CORS 문제 해결**
```
"CORS 에러가 왜 생기는가?"
→ Eruda Network tab
→ "Access-Control-Allow-Origin missing" 보임
→ 서버 팀에 요청 (헤더 추가)
```

---

## Part 5: 마스터플랜 재조정

### ❌ 제거할 항목

- Priority 3.1: Response Caching Analysis (Eruda 중복)
- Priority 3.2: CORS/Security Analysis (Eruda가 더 잘함)

### ✅ 유지할 항목

**Priority 1 (Core):**
- 1.1 Response Body Formatting
- 1.2 Timing Waterfall
- 1.3 Initiator Stack Trace

**Priority 2 (UX):**
- 2.1 Advanced Filtering
- 2.2 Export Network Data
- 2.3 Request Replay

**Priority 3 (Polish):**
- 3.3 Performance Metrics (단순화)
- 3.4 Request Grouping

### 수정된 로드맵

**Phase 1: Core Performance** (2-3 sprints)
```
1. Timing Waterfall visualization
2. Initiator Stack Trace capture
3. Response Body Formatting (JSON/HTML/Image)
```

**Phase 2: Advanced Debugging** (3-4 sprints)
```
1. Advanced Filtering (slow requests, status codes)
2. Export Functionality (HAR/JSON/CSV)
3. Request Replay
```

**Phase 3: Analytics** (2-3 sprints)
```
1. Performance Metrics Dashboard
2. Request Grouping & Organization
3. Slow request detection & alerts
```

---

## Part 6: 기술적 고려사항

### Eruda와의 통신

**현재 (독립적):**
```
Wallnut DevTools: 독립적 구현
Eruda: 독립적 구현
```

**향후 고려 (선택사항):**
```
Wallnut이 Eruda 데이터 활용?
→ Eruda JavaScript는 WKWebView 내부만 접근
→ Swift에서 접근 복잡
→ 중복 캡처보다 역할 분담이 낫다
```

### JavaScript Hook 활용

**Wallnut의 이점:**
- 이미 JavaScriptHook 구현됨
- fetch/XHR 완벽하게 캡처 가능
- Eruda보다 더 많은 메타데이터 수집 가능 (stack trace!)

**Stack Trace 캡처 예:**
```javascript
// Wallnut의 향상된 hook
function sendLog(type, args) {
    const stack = new Error().stack;  // ← Stack trace 캡처
    const logData = {
        type,
        args,
        stack,  // ← 새로운 필드
        caller: extractCallerInfo(stack)
    };
    window.webkit.messageHandlers.consoleLog.postMessage(logData);
}

fetch(url) → Wallnut hook 캡처
→ Stack trace 포함: "main.js:123 → api.js:45"
→ Swift에서 "이 요청은 main.js의 123번째 줄에서 시작"
```

---

## Part 7: 최종 권장사항

### Wallnut Network 개선 목표

**1순위: Wallnut만 할 수 있는 것**
- ✅ Timing waterfall (매우 큼)
- ✅ Stack trace (매우 큼)
- ✅ Response formatting (보기 좋음)

**2순위: 사용성**
- ✅ Advanced filtering
- ✅ Export functionality

**3순위: 피하기**
- ❌ CORS 분석 (Eruda가 더 잘함)
- ❌ 캐싱 분석 (Eruda가 더 잘함)

### 메시지

```
"Wallnut과 Eruda는 경쟁이 아니라 보완"

- Eruda: 페이지 내부 기본 모니터링 (빠르고 간편)
- Wallnut: 성능 분석 + 고급 디버깅 (깊이 있음)

사용자가 둘 다 사용하면 최강의 개발자 도구!
```

---

**Status**: 재평가 완료, 마스터플랜 조정됨
**Owner**: Wallnut Development Team
**Last Updated**: 2025-12-22
