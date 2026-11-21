---
name: flow-window
description: Flow 앱 창(윈도우)의 처음 크기·위치·최소 크기·제목·투명 설정을 만들거나 고칠 때 먼저 불러온다. lib/main.dart의 WindowOptions, windowManager, lib/services/window_fit.dart, "창이 화면보다 커", "창 크기", "창 위치", "모니터" 요청에 사용한다.
---

# Flow 창 크기·위치 규칙

사용자 지시(2026-11-21): **실행한 창이 모니터보다 크면 제목줄이 화면 밖으로 나가 마우스로 옮길 수 없다. 창은 항상 보여줄 모니터 화면보다 작게 띄운다.**

## 규칙

1. 원하는 크기는 `kDesiredWindowSize = 650x900` (논리 픽셀). 고정값으로 바로 쓰지 않는다.
2. 처음 띄울 때 주 모니터의 **작업 영역**(작업표시줄 제외)을 `screen_retriever`의 `getPrimaryDisplay()` → `visiblePosition`/`visibleSize`로 읽는다. 이 값은 Windows에서 이미 배율(DPI)로 나눈 논리 픽셀이라 window_manager와 단위가 같다.
3. `fitWindowToScreen()` (`lib/services/window_fit.dart`):
   - 가로·세로 각각 작업 영역의 **90%**를 넘지 않게 줄인다.
   - 작업 영역 가운데에 놓되, **top은 작업 영역 top보다 위로 가지 않는다**(제목줄 보장).
4. 최소 크기 `kMinWindowSize = 300x500`도 `fitMinimumSize()`로 맞춘 크기보다 크지 않게 줄인다(최소 크기가 모니터보다 크면 다시 넘친다).
5. `WindowOptions(center: false, size: 맞춘 크기)` → `waitUntilReadyToShow` 안에서 `setBounds(맞춘 Rect)` 후 show. `center: true`를 쓰지 않는다(크기 맞춘 뒤 위치를 직접 정함).
6. 모니터 정보를 못 읽으면(예외) 작업 영역 1280x680으로 가정해 맞춘다.
7. 창 제목은 `Flow v<버전>` (flow-versioning).

## 검사

- `test/window_fit_test.dart`: 큰 모니터는 650x900 그대로, 1920x1080 배율 150%(작업 영역 1280x680)에서는 높이 612, 창 전체가 작업 영역 안, 최소 크기 축소.
- 창 크기 규칙을 바꾸면 이 테스트도 함께 고친다.

## 모니터 확인법 (디버깅)

```
powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Screen]::AllScreens | % { $_.DeviceName + ' ' + $_.Bounds + ' work ' + $_.WorkingArea }"
```
(이 PC: 2560x1440 주 모니터 + 1920x1080 두 대, 2026-11-21. 표시 값은 프로세스 DPI 인식에 따라 물리/논리가 섞일 수 있음)
