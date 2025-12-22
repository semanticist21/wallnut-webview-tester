# Eruda Network Reality Check (Wallnut 기준 보완 메모)

**목적**: 기존 `claudedocs/NETWORK_STRATEGY_ANALYSIS.md`의 Eruda 관련 내용을 실제 소스 기준으로 정정/보완한다.

---

## 1) Eruda Network 구현 범위 (소스 기반)

**근거 파일**: `eruda/src/Network/Network.js`, `eruda/src/Network/Detail.js`

- **수집 방식**: `chobitsu` Network domain 이벤트(`requestWillBeSent`, `responseReceived`, `loadingFinished`) 기반.
- **타이밍 정보**: 총 소요시간만 표시 (`startTime` → `loadingFinished`), **워터폴 단계 없음**.
- **응답 바디**: `Network.getResponseBody()`의 `body`만 사용하며 **100,000자 제한**. (`MAX_RES_LEN = 100000`)
- **필터링**: 단일 텍스트 필터(컬럼별/조건별 고급 필터 없음).
- **재현**: cURL 복사 기능 제공(요청 재현의 “수동” 대체).

---

## 2) 문서 내 과장 가능성 정정 포인트

### 2.1 캐싱 분석
- **실제**: Eruda는 Cache-Control/ETag/Last-Modified를 **표시**할 뿐, 분석/추천 로직은 없음.
- **정정 제안**: “Eruda가 캐싱을 잘 분석” → “Eruda는 캐싱 관련 헤더를 직접 확인 가능” 수준으로 다운그레이드.

### 2.2 CORS/보안 분석
- **실제**: Eruda는 헤더 표시 가능하지만, **CORS로 노출 제한**이 걸릴 수 있음.
- **정정 제안**: “Eruda가 CORS를 잘 분석” → “Eruda는 페이지 컨텍스트에서 헤더 확인 가능하나, 교차 도메인은 제한적”

---

## 3) Wallnut와의 역할 분담 보강 포인트

- **Eruda**: 빠른 확인(헤더/바디/간단 필터), cURL 복사 제공
- **Wallnut**: 워터폴, 스택 트레이스, 고급 필터, Export, Replay

**차별 강조**:
- Eruda는 **총 duration**만 제공 → Wallnut은 **단계별 타이밍** 제공
- Eruda의 cURL 복사 → Wallnut의 **수정/재전송 리플레이**와 구분

---

## 4) 추가로 적어두면 좋은 실무 가이드

- **동시 사용 시 고려**: Eruda + Wallnut 둘 다 JS hook 사용 → 성능/노이즈 증가 가능.
- **권장**: 일반 디버깅은 Eruda, 성능/원인 분석은 Wallnut 중심.

---

## 5) 소스 참조

- `eruda/src/Network/Network.js`
- `eruda/src/Network/Detail.js`
- `eruda/src/Network/util.js`
- `eruda/src/lib/chobitsu.js`
