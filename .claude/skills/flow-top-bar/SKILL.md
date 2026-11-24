---
name: flow-top-bar
description: Flow 메인 화면 상단바(TopBar, lib/widgets/top_bar.dart)의 컨트롤 아이콘 행(+ 접기/펼치기, Daily, 알아차림, 모드, 테마, 메모, 끝장 리스트, 설정), 아이콘 크기·간격, Daily 스케줄 박스 폭, 목표 제목·티커 배치를 만들거나 고칠 때 먼저 불러온다. "상단바", "상단 아이콘", "컨트롤 아이콘", "Daily 아이콘", "모드/테마 버튼" 요청에 사용한다.
---

# 메인 화면 상단바 (TopBar) 규격

이 문서만 보고 같은 결과를 다시 만들 수 있어야 한다. 테스트: `test/top_bar_test.dart`.

## 구조 (`_TopBarState.build`, `Stack`)

0. (`showDailyScheduleBox`일 때) Daily 스케줄 박스: top 24, 폭 `targetWidth`.
1. 컨트롤 아이콘 행: top `buttonRowTop`(박스 있으면 112, 없으면 2).
2. 목표 제목 `GoalTitleDisplay`: bottom `티커 높이 + 10`.
3. 티커 `TopBarTicker`: bottom 2.

## 컨트롤 아이콘 행 (2026-11-24 사용자 지시)

- 순서: **+ 접기/펼치기** · Daily(`calendar_today_rounded`) · 알아차림(`psychology_outlined`) · 모드(`dashboard_customize` + 모드 이름) ‖ 간격 ‖ 테마(`palette_outlined`) · 메모(원) · 끝장 리스트(원) · 설정(원). 버튼끼리 간격 12.
- **크기는 예전의 2/3**: `_iconScale = 2/3`, `iconSize = unifiedFontSize * _iconScale`를 행의 모든 `ClayButton.size`에 쓴다. 행 높이도 `(maxHeight*0.25).clamp(90,165) * 0.35 * _iconScale`. 행 폭은 `_calculateUnscaledIconsRowWidth(iconSize, …)`와 `containerWidth` 중 작은 값(`iconsTargetWidth`), `FittedBox(scaleDown)`.
  - 폭 계산식 간격 = `12*6 + _modeThemeGap`, + 버튼 몫 `buttonSize*0.45 + 44`.
  - Daily 스케줄 박스 폭(`targetWidth`)은 **예전 크기(unifiedFontSize) 기준을 유지**한다(아이콘만 줄임, 박스 글이 좁아지지 않게).
- **모드·테마 사이 간격** `_modeThemeGap = 70` (예전 30의 2배 이상). 사용자 지시라 줄이지 않는다.
- **+ 버튼**: Daily 앞. `_controlsExpanded`(기본 true, 앱 실행 중에만 기억). 펼침 상태 아이콘 `Icons.remove`·툴팁 `컨트롤 접기`, 접힘 상태 `Icons.add`·`컨트롤 펼치기`. 색 `theme.primaryColor`. 접으면 + 버튼만 남고(`if (_controlsExpanded) ...[ ]`로 나머지 숨김) `FittedBox.alignment`가 `centerLeft`가 된다.

## 주의

- `dart format`은 **바꾼 파일만** 지정한다. `lib/widgets/*.dart`처럼 한꺼번에 돌리면 손대지 않은 14개 파일이 바뀌어 analyze 경고가 늘어난다(2026-11-24 실수, `git checkout`으로 되돌림).
