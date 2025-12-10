# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Wallnut (wina)** - iOS WKWebView 테스터 앱

WKWebView의 다양한 설정 옵션을 실시간으로 테스트하고 검증하기 위한 도구. 개발자가 WebView 동작을 빠르게 확인하고 디버깅할 수 있도록 지원.

### 주요 기능
- WKWebView 설정 옵션 토글 (JavaScript, 쿠키, 줌, 미디어 자동재생 등)
- User-Agent 커스터마이징
- URL 입력 및 웹페이지 로딩 테스트
- WKWebView Info: Device, Browser, API Capabilities (46개+), Media Codecs, Performance, Display, Accessibility
- Info 전체 검색: 모든 카테고리에서 통합 검색 가능 (Active Settings 20개 항목 포함)
- 권한 관리: Settings에서 Camera, Microphone, Location 권한 요청/확인

## Build & Run

```bash
# Xcode로 빌드
open wina.xcodeproj
# Cmd+R로 실행

# CLI 빌드 (시뮬레이터)
xcodebuild -project wina.xcodeproj -scheme wina -sdk iphonesimulator build

# 특정 시뮬레이터 지정 빌드
xcodebuild -project wina.xcodeproj -scheme wina -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Architecture

SwiftUI 기반 단일 타겟 iOS 앱. 최소 지원 버전: iOS 26.1 (Tahoe)

```
wina/
├── winaApp.swift              # App entry point (@main), 다크모드 상태 관리
├── ContentView.swift          # Root view, URL 입력 + 최근 URL 기록
├── SettingsView.swift         # WebView 설정 (20개 항목) + 권한 관리 (Camera, Mic, Location)
├── Features/
│   ├── AppBar/                # 상단 바 버튼들
│   │   ├── ThemeToggleButton.swift
│   │   ├── SettingsButton.swift
│   │   └── InfoButton.swift
│   └── Info/                  # WKWebView 정보 표시 (8개 서브메뉴 + 전체 검색)
│       └── InfoView.swift     # 단일 파일에 모든 Info 뷰/모델 포함 (~2400줄)
├── Shared/Components/         # 재사용 컴포넌트
│   ├── GlassIconButton.swift  # 원형 glass effect 버튼
│   ├── ChipButton.swift       # 탭 가능한 칩 버튼
│   └── FlowLayout.swift       # 자동 줄바꿈 Layout
└── Resources/Icons/           # 앱 아이콘 원본
```

### 데이터 흐름
- `@AppStorage` 사용하여 설정 값 UserDefaults 영속화
- Sheet 기반 모달 (Settings, Info)
- WKWebView JavaScript 평가로 브라우저 capability 감지

## Design System

**Liquid Glass UI** - iOS 26 (Tahoe) 공식 Glass Effect

```swift
.glassEffect()                            // 기본
.glassEffect(in: .capsule)                // 캡슐
.glassEffect(in: .circle)                 // 원형
.glassEffect(in: .rect(cornerRadius: 16)) // 라운드 사각형
```

### 디자인 원칙
- `.glassEffect()` modifier 사용 (Material 대신)
- 시스템 기본 배경 유지 (임의 배경색 X)
- `.secondary`, `.primary` 등 시스템 색상 활용

## Code Conventions

| 대상 | 컨벤션 | 예시 |
|------|--------|------|
| 파일명, 타입 | PascalCase | `ContentView.swift` |
| 변수, 함수 | camelCase | `urlText`, `loadPage()` |
| 에셋 | kebab-case | `app-icon` |

### 파일 구성
- 1파일 1컴포넌트 원칙 (public View 기준)
- 150줄 이하 유지 권장
- 해당 파일 전용 helper는 같은 파일에 `private`으로 선언

### 작업 규칙
- 끝나면 항상 문법검사 수행
- 빌드 검증은 통합적인 작업 이후에만 확인 (시간 소요)

## iOS 26 주의사항

```swift
// ❌ Deprecated
UIScreen.main.bounds

// ✅ iOS 26+
let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
scene?.screen.bounds
UITraitCollection.current.displayScale
```

## Image Conversion

SVG → PNG 변환 시 `rsvg-convert` 사용 (ImageMagick은 색상이 어둡게 변환됨)

```bash
# 올바른 방법
rsvg-convert -w 1024 -h 1024 input.svg -o output.png

# 사용하지 말 것 (색상 왜곡)
magick input.svg output.png
```

## WKWebView API Capability 체크 주의사항

### Info.plist 권한이 필요한 API
앱에 권한이 선언되지 않으면 WebKit이 API를 노출하지 않아 false 반환:
- **Media Devices / WebRTC**: `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`
- **Geolocation**: `NSLocationWhenInUseUsageDescription`

**현재 등록된 권한** (`Info.plist` - 프로젝트 루트):
- `NSCameraUsageDescription`: 카메라 (Media Devices, WebRTC 테스트용)
- `NSMicrophoneUsageDescription`: 마이크 (Media Devices, WebRTC 테스트용)
- `NSLocationWhenInUseUsageDescription`: 위치 (Geolocation 테스트용)

> 실제 권한 요청 다이얼로그를 표시하려면 `WKUIDelegate`의 `requestMediaCapturePermission` 구현 필요

### WKWebView에서 항상 미지원 (WebKit 정책)
Safari에서만 지원되거나 WebKit에서 구현하지 않은 API:
- **Service Workers**: Safari/홈 화면 PWA 전용. WKWebView는 App-Bound Domains 필요
- **Web Push Notifications**: Safari/홈 화면 PWA 전용 (iOS 16.4+)
- **Vibration, Battery, Bluetooth, USB, NFC**: WebKit 보안/개인정보 정책으로 미구현

### iOS 특수 API

- **MediaSource**: iOS 17+에서 `ManagedMediaSource` 사용 (기존 MSE 미지원, WKWebView에서는 N/A)
- **localStorage/sessionStorage**: `loadHTMLString` 사용 시 `baseURL`을 실제 URL로 설정해야 접근 가능

## Performance 벤치마크

3DMark 스타일 점수 시스템. **iPhone 14 Pro = 10,000점** 기준.

### 벤치마크 항목

| 카테고리 | 테스트 |
|----------|--------|
| JavaScript | Math, Array, String, Object, RegExp |
| DOM | Create, Query, Modify |
| Graphics | Canvas 2D, WebGL |
| Memory | Allocation, Operations |
| Crypto | Hash |

### 레퍼런스 값 (iPhone 14 Pro)

`PerformanceInfo.reference` 딕셔너리에 정의됨. 새 기기 측정 시 이 값 업데이트 가능.

### 주의사항

- 벤치마크 JavaScript는 동기 실행 필수 (async/await 사용 시 WKWebView에서 "unsupported type" 에러)
- Canvas/WebGL은 `document.createElement`로 동적 생성 (HTML 내 element는 `baseURL: nil`일 때 접근 불가할 수 있음)

## Info 검색 구조

`InfoView`의 `allItems` computed property가 모든 검색 가능 항목을 통합:
- Active Settings (20개): 현재 WebView 설정 상태 (항상 표시), Settings 바로가기 버튼 포함
- Device, Browser, API, Codecs, Display, Accessibility: 데이터 로드 후 검색 가능
- Performance: 항목만 노출 (`linkToPerformance: true`), 클릭 시 벤치마크 화면으로 이동

검색 결과는 `filteredItems`에서 카테고리별로 그룹화되어 표시.

## Settings 구조

SettingsView에서 관리하는 모든 WKWebView 설정 (20개):

| 섹션 | 설정 |
|------|------|
| Core | JavaScript, Content JavaScript, Ignore Viewport Scale Limits, Minimum Font Size |
| Media | Auto-play Media, Inline Playback, AirPlay, Picture in Picture |
| Navigation | Back/Forward Gestures, Link Preview |
| Content Mode | Recommended / Mobile / Desktop |
| Behavior | JS Can Open Windows, Fraudulent Website Warning, Text Interaction, Element Fullscreen API, Suppress Incremental Rendering |
| Data Detectors | Phone Numbers, Links, Addresses, Calendar Events |
| Privacy & Security | Private Browsing, Upgrade to HTTPS |
| User-Agent | Custom User-Agent string |
| Permissions | Camera, Microphone, Location |

모든 설정은 `@AppStorage`로 UserDefaults에 영속화됨.

## Info 버튼 컴포넌트

Info 뷰에서 사용되는 재사용 컴포넌트들:
- `InfoRow`: 라벨-값 쌍 표시, 선택적 info 버튼
- `CapabilityRow`: 지원 여부 체크마크 표시, 선택적 info 버튼, unavailable 플래그
- `ActiveSettingRow`: 설정 상태 표시 (enabled/disabled), 선택적 info 버튼
- `BenchmarkRow`: 벤치마크 결과 표시 (ops/s), 선택적 info 버튼
- `CodecRow`: 코덱 지원 상태 (probably/maybe/none)

info 버튼 클릭 시 popover로 설명 표시 (통일된 스타일).
