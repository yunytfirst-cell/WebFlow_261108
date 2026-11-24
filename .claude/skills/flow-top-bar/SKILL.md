---
name: flow-top-bar
description: Flow 메인 화면 상단바(TopBar, lib/widgets/top_bar.dart)의 컨트롤 아이콘 행(+ 접기/펼치기, Daily, 알아차림, 모드, 테마, 메모, 끝장 리스트, 설정), 아이콘 크기·간격, Daily 스케줄 박스 폭, 목표 제목·티커 배치를 만들거나 고칠 때 먼저 불러온다. "상단바", "상단 아이콘", "컨트롤 아이콘", "Daily 아이콘", "모드/테마 버튼" 요청에 사용한다.
---

# 메인 화면 상단바 (TopBar) 규격

이 문서만 보고 같은 결과를 다시 만들 수 있어야 한다. 테스트: `test/top_bar_test.dart`.

## 구조 (`_TopBarState.build`, `Stack`)

- **위쪽 여백** `TopBar.topGap = 24` (2026-11-24 사용자 지적 "컨트롤 바 위쪽 높이 간격 20~30 줄 것, 시각적으로 불편"; 원인: 아이콘 행이 top 2로 창 위 끝에 붙어 있었음). `preferredSize`에 더하고, 아이콘 행 top·Daily 스케줄 박스 top(24 → topGap+24)에도 더한다. **main.dart 본문 시작 SizedBox 높이에도 `TopBar.topGap`을 더한다**(안 그러면 본문과 겹침).

0. (`showDailyScheduleBox`일 때) Daily 스케줄 박스: top `topGap + 24`, **`left: _barLeft`, `width: _barWidth`** (2026-11-24 사용자 지시: −/+ 버튼 왼쪽 끝 ~ 설정 아이콘 오른쪽 끝, 목표바와 같은 잰 값). 재기 전 첫 프레임만 예전처럼 `targetWidth` 가운데.
   - `DailyScheduleBox`(`lib/widgets/daily_schedule_box.dart`) 구조 (2026-11-24 사용자 지시 "현재시간을 왼쪽 끝으로" → "시간 앞 아이콘·감싸는 박스 제거, 박스 왼쪽 끝~시간 끝까지 컬러로 표시"): 바깥 Container(높이 76, 패딩 없음, `clipBehavior: antiAlias`, 배경 primary 0.35·모서리 14·그림자는 decoration, **테두리는 `foregroundDecoration`** — 색 칸이 테두리를 덮지 않게) → `Row(stretch)[ 시간 색 칸, Expanded(Padding(10/6, 예전 FittedBox 내용)) ]`.
     - 시간 색 칸: `Container(color: accentColor 0.6, 가로 패딩 12, 가운데)` 안에 `FittedBox(Text HH:mm, 20, w900, tabularFigures)`. 시계 아이콘·검은 둥근 박스는 **없다**.
     - 오른쪽 내용: 시간대 라벨·스케줄 글(누르면 편집) → 6 → 닫기(X). 스케줄 아이콘(`schedule_rounded`)은 **없다**(2026-11-24 사용자 지시 "현재시간 우측 아이콘 제거"). 기준 폭 최소 220(`referenceWidth`).
1. 컨트롤 아이콘 행: top `buttonRowTop = topGap + (박스 있으면 112, 없으면 2)`.
2. 목표 제목 `GoalTitleDisplay`: bottom `티커 높이 + 10`.
3. 티커 `TopBarTicker`: bottom 2.

## 컨트롤 아이콘 행 (2026-11-24 사용자 지시)

- 순서: **+ 접기/펼치기** · Daily(`calendar_today_rounded`) · 알아차림(`psychology_outlined`) · 모드(`dashboard_customize` + 모드 이름) ‖ 간격 ‖ 테마(`palette_outlined`) · 메모(원) · 끝장 리스트(원) · 설정(원). 버튼끼리 간격 12.
- **크기는 예전의 2/3**: `_iconScale = 2/3`, `iconSize = unifiedFontSize * _iconScale`를 행의 모든 `ClayButton.size`에 쓴다. 행 높이도 `(maxHeight*0.25).clamp(90,165) * 0.35 * _iconScale`. 행 폭은 `_calculateUnscaledIconsRowWidth(iconSize, …)`와 `containerWidth` 중 작은 값(`iconsTargetWidth`), `FittedBox(scaleDown)`.
  - 폭 계산식 간격 = `12*6 + _modeThemeGap`, + 버튼 몫 `buttonSize*0.45 + 44`.
  - `targetWidth`(예전 크기 기준 폭)는 이제 Daily 박스·목표바의 첫 프레임 대체값으로만 쓴다.
- **모드·테마 사이 간격** `_modeThemeGap = 70` (예전 30의 2배 이상). 사용자 지시라 줄이지 않는다.
- **+ 버튼**: Daily 앞. `_controlsExpanded`(기본 true, 앱 실행 중에만 기억). 펼침 상태 아이콘 `Icons.remove`·툴팁 `컨트롤 접기`, 접힘 상태 `Icons.add`·`컨트롤 펼치기`. 색 `theme.primaryColor`. 접으면 나머지 버튼을 `_keepPlaceWhenCollapsed([...])`(`Visibility(visible: _controlsExpanded, maintainSize/Animation/State: true)`)로 **자리는 그대로 두고 보이지 않고 눌리지 않게** 한다. `FittedBox.alignment`는 항상 center.
  - 사용자 지적(2026-11-24 "− 누르면 + 버튼 위치가 다른 곳으로 바뀐다"): 원인은 예전에 `if (_controlsExpanded) ...[ ]`로 버튼을 트리에서 빼서 행 폭과 FittedBox 축소 비율이 바뀌고 정렬도 centerLeft로 바뀐 것. **버튼을 트리에서 빼지 않는다.** 아이콘 행 측정도 접힌 상태에서 계속 같은 값이 나온다.
  - 테스트: 접기 전후·다시 펼친 뒤 + 버튼 `getRect`가 같고, 숨긴 버튼은 `hitTestable()`로 찾히지 않는다.

## 목표바(목표 제목 + 티커) 정렬·글자 (2026-11-24 사용자 지시)

- "−/+ 버튼 앞쪽과 목표바 시작 위치를 정렬, 끝은 설정 아이콘 끝에 맞춤": 아이콘 행 바깥 Row에 `_iconsRowKey`, Stack에 `_stackKey`. build마다 `addPostFrameCallback(_measureIconsRow)`로 Row의 왼쪽·오른쪽 끝을 `localToGlobal(…, ancestor: stackBox)`로 잰다(FittedBox 축소가 반영됨). 0.5 넘게 바뀌었을 때만 setState(무한 루프 방지). 접힌 상태에서도 숨긴 버튼이 자리를 차지하므로 값이 같다.
- `GoalTitleDisplay`와 `TopBarTicker`의 `Positioned`는 `left: _barLeft, width: _barWidth`(잰 값이 없을 때 첫 프레임은 예전처럼 `(maxWidth-120).clamp(180,700)` 가운데). 티커에는 `columnWidth: tickerWidth`, `maxWidth: null`을 넘긴다(maxWidth를 넘기면 티커가 자기 폭을 따로 계산해 어긋남).
- "목표바 안의 글자도 오토레이아웃": `_getTickerFontSize()` = 예전 값(base)과 `_barWidth * 0.045` 중 작은 값(최소 11). 티커 줄 높이(`_getTickerBarHeight`)도 같은 함수를 쓰므로 함께 줄어든다.
- 테스트: `test/top_bar_test.dart`가 티커·목표 제목·Daily 박스의 좌우 끝이 −버튼 왼쪽·설정 오른쪽과 1 이내로 같은지 검사한다. Daily 박스는 현재 시간이 스케줄 아이콘보다 왼쪽, 시계·스케줄 아이콘 없음, 색 칸이 박스 왼쪽 끝에서 시작해 시간 글자 끝을 지나는지도 본다.

## 목표 표시바 = ITEM FINISH 바 (2026-11-24 사용자 지시 "목표 표시바, item finish 바의 사이즈·위치·글자크기 동일")

- `GoalTitleDisplay`: 높이 `fontSize * 1.5`(티커 줄 높이와 같음), 패딩 없음, Row `start`·`max`, `목표: `·입력 글·힌트 모두 `fontSize`(예전 0.9/0.85 배율 없앰), 굵게.
- `TopBarTicker` 글 영역 Container `alignment: centerLeft`(예전 center라 짧은 `ITEM FINISH`가 가운데에 있었음).
- 두 바 모두 `left: _barLeft, width: _barWidth`, 같은 `tickerFontSize`. 테스트가 크기·글자 크기·글자 시작 x(`목표: ` vs `ITEM FINISH`)가 같은지 본다.

## 주의

- `dart format`은 **바꾼 파일만** 지정한다. `lib/widgets/*.dart`처럼 한꺼번에 돌리면 손대지 않은 14개 파일이 바뀌어 analyze 경고가 늘어난다(2026-11-24 실수, `git checkout`으로 되돌림).
