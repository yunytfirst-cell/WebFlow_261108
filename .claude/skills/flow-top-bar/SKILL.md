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
2. 목표 제목 `GoalTitleDisplay`: bottom `_goalTitleBottom(containerHeight)` (2026-11-25 사용자 지시 "상단바와 목표 박스 간격을 지금의 1/2로, STEP 박스 위치는 바꾸지 말 것"). 예전 자리(bottom `티커 높이 + 10`)에서 아이콘 행 **실제 아래 끝**(`_measureIconsRow`가 재는 `_rowBottom`, FittedBox 축소 반영)까지의 간격 × `goalGapRatio`(0.5)만큼 위로 올린다. 재기 전 첫 프레임·간격이 0 이하면 예전 자리.
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
- 두 바 모두 `left: _barLeft, width: _barWidth`, 같은 `tickerFontSize`. 테스트가 크기가 같은지 본다(2026-11-25부터 ITEM FINISH는 가운데 깃발 아이콘이라 글자 시작 x 비교는 없앰).

## STEP > 박스 글자 (2026-11-25 사용자 지시)

- 티커 글자(`ITEM FINISH`, `STEP > n. …`)는 목표 박스 글자의 **2/3** (`TopBarTicker.textScale`). 박스 높이·itemExtent·위아래 버튼 크기는 `fontSize` 기준 그대로라 STEP 박스 위치·크기는 그대로다.
- 그래서 "목표 바와 ITEM FINISH 글자 크기 같음" 규칙은 이제 "ITEM FINISH = 목표 × 2/3"이다. 크기·글자 시작 x는 여전히 같다. 테스트가 둘 다 검사한다.

## 🎯 보내기 전·후 아이콘 슬라이드 (2026-11-25 사용자 지시 "목표도 동일하게 끝장리스트에서 메인화면 보내기를 누르면 보이게, 목표 아이콘과 FINISH 아이콘은 보내기 전에는 모두 우측에 있다가, 누르면 서서히 좌측으로 표시할 글자와 같이 움직인다")

- 상태: `active = !_showInitialMessage`(TopBar). 티커는 `showInitialMessage`로, `GoalTitleDisplay`는 `active:`로 받는다(기본 false).
- 보내기 전(active false): 과녁 아이콘은 목표 박스 **오른쪽 끝**, FINISH 아이콘은 STEP 박스 **오른쪽 끝**. 목표 글·STEP 글은 박스 오른쪽 밖에 있어 `ClipRect`로 보이지 않는다.
- 🎯 누르면(active true): 두 아이콘이 `TopBarTicker.slideDuration`(900ms) 동안 `Curves.easeInOutCubic`로 왼쪽 끝까지 움직이고, 글은 **아이콘 오른쪽(간격 fontSize*0.4)에 붙어 함께** 들어온다. 닫으면(선택 해제) 반대로 오른쪽으로 돌아간다.
- 구현: 바깥 `SizedBox(박스 폭, 박스 높이)` → `Stack(clipBehavior: none)[ Positioned.fill(ClipRect(Stack[ Positioned(left: iconLeft+아이콘폭+간격, 글) ])), Positioned(left: iconLeft, 아이콘) ]`. iconLeft = `(박스 폭 − 아이콘 폭) × (1 − t)`, t는 `TweenAnimationBuilder<double>(tween: Tween(end: active ? 1 : 0))`의 진행값.
  - **AnimatedPositioned를 쓰지 않는 이유**(사용자에게 보인 문제는 아니고 테스트에서 잡음): 시작 직후 목표바 폭을 다시 재면(700→592) AnimatedPositioned가 새 위치로 0.9초 동안 미끄러져, 🎯를 안 눌러도 아이콘이 움직였다. 진행값만 애니메이션하면 폭 변화는 바로 반영되고 🎯 상태 변화만 서서히 움직인다.
  - STEP 글 폭 = 박스 폭 − 아이콘 폭 − 간격 − 조작 버튼 폭(85). 조작 버튼(↑↓×)은 active일 때 오른쪽(`top: 0`).
  - `FinishFlagIcon.widthFor(height) = height*0.72*1.5`로 아이콘 폭을 밖에서 계산한다.
- 테스트(`🎯로 보내면 아이콘이 글과 함께 왼쪽으로 움직인다`): 보내기 전 두 아이콘 오른쪽 끝·글은 박스 밖, 절반 시간에 깃발이 중간 위치·글이 깃발 오른쪽 20 이내, 끝나면 두 아이콘 왼쪽 끝·글은 아이콘 오른쪽 박스 안, 선택 해제하면 다시 오른쪽.

## "목표:" = 과녁 아이콘 (2026-11-25 사용자 지시 "목표: 글자 첨부된 아이콘으로 변경, 하단(FINISH 아이콘) 설정과 동일")

- `GoalTitleDisplay`의 `목표: ` 글자 대신 `Image.asset(GoalTitleDisplay.iconAsset = 'assets/images/goal_target.png')`(툴팁 `목표`) + 간격 `fontSize*0.4` → 제목 입력칸.
- 크기는 아래 FINISH 아이콘과 같다: `GoalTitleDisplay.iconScale = 0.95 * 1.5` × 박스 높이. Row 안 자리는 `SizedBox(폭 = 아이콘 크기, 높이 = 박스 높이)` + `OverflowBox`로 **위아래로 넘치게** 그린다(박스 위치·높이 그대로). 1280×800에서 설정 아이콘·FINISH 깃발과 겹치지 않는다(테스트).
- 에셋 만들기: 첨부 PNG를 PIL로 네 모서리에서 `floodfill(thresh=40)`해 바깥 흰 바탕만 투명하게(안쪽 흰 띠는 그대로) → `getbbox()`로 자르고 정사각형 투명 캔버스 가운데에 붙여 저장. 어두운 바탕에 합성한 미리보기를 Read로 확인. `pubspec.yaml` assets에 경로 추가.
- 테스트: `목표: ` 글자 없음, 에셋 Image 하나, 높이 = 깃발 높이, 왼쪽 끝 = 목표 박스 왼쪽, 위 끝 ≥ 설정 아이콘 아래, 아래 끝 ≤ 깃발 위.

## ITEM FINISH = 깃발 아이콘 (2026-11-25 사용자 지시, 첨부 이미지 "엇갈린 체크무늬 깃발 + FINISH")

- "ITEM FINISH" 글자 대신 `FinishFlagIcon`(`lib/widgets/finish_flag_icon.dart`). 1.5.1~1.5.3에는 가운데에 있다가 🎯 누르면 사라졌지만, 1.6.0부터는 위 "🎯 보내기 전·후 아이콘 슬라이드" 규칙(보내기 전 오른쪽, 보내면 STEP 글과 함께 왼쪽)을 따른다.
- `FinishFlagIcon(height: viewportHeight * TopBarTicker.finishIconScale, …)` — `finishIconScale = 0.95 * 1.5` (2026-11-25 사용자 지시 "아이콘 지금의 1.5배"). 박스보다 크므로 `OverflowBox(maxHeight: 그 높이, alignment: bottomCenter)`로 감싸 **아래 끝은 박스 아래 끝, 위로 넘치게** 한다. 티커 Stack은 `clipBehavior: Clip.none`, ClipRect는 STEP 목록(ListView)에만 둔다(아이콘까지 감싸면 잘림). STEP 박스 위치·크기는 그대로. 1280×800에서 아이콘 위 끝(137.6)은 목표 박스 아래 끝(120.7)보다 아래라 겹치지 않는다. poleColor: theme.textColor, textColor: theme.accentColor, 툴팁 `ITEM FINISH`. 위 72% = 깃발(폭 = 높이×1.5, `CustomPainter`), 아래 = `FINISH`(w900, 자간 2, 깃발 폭의 80%에 FittedBox).
- 깃발 그리기: 설계 좌표 120×80, 왼쪽 깃대 (50,3)→(74,79) 굵기 4 둥근 끝, 깃발 네 모서리 (50,3)·(62,44)·(6,56)·(1,14)를 쌍선형으로 7×5칸 나눠 흑/백 번갈아 칠하고 흰 테두리 1.5. 오른쪽은 x → 120−x 반전(깃대가 X로 교차).
- 모양 확인법: 임시 테스트에서 `RepaintBoundary`+`matchesGoldenFile` 후 `--update-goldens`로 PNG를 만들어 Read로 보고 지운다(테스트 글꼴이라 글자는 네모로 보임). 첫 버전은 깃발이 작고 글자가 넓어서 비율을 고쳤다.
- 테스트: `ITEM FINISH` 글자 없음, `FinishFlagIcon` 하나, 가운데 x가 티커 가운데와 1 이내, 높이 = 티커 높이×0.95×1.5, 아래 끝 = 티커 아래 끝, 위 끝이 설정 아이콘·목표 박스보다 아래.

## 주의

- `dart format`은 **바꾼 파일만** 지정한다. `lib/widgets/*.dart`처럼 한꺼번에 돌리면 손대지 않은 14개 파일이 바뀌어 analyze 경고가 늘어난다(2026-11-24 실수, `git checkout`으로 되돌림). **top_bar.dart·top_bar_ticker.dart는 원래 포맷되지 않은 파일이라 바꿨어도 `dart format`을 돌리지 않는다** — 2026-11-25에 돌렸더니 파일 전체가 바뀌고 curly_braces 경고 4개가 늘어 `git checkout` 후 고친 부분만 다시 넣었다.
