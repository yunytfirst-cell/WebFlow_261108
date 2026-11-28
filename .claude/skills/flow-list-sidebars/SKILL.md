---
name: flow-list-sidebars
description: Flow 앱의 "성공의 열쇠(끝장 리스트, GoalListSidebar)"와 "알아차림 리스트(AwarenessListSidebar)"의 규격·스타일·규칙. 두 사이드바, 리스트 txt 파일 형식, 실행 카운터(오늘 실행/누적), 저장·불러오기·새로만들기·폴더관리, list_file_service.dart, run_counter_service.dart, run_counter_panel.dart, main.dart의 사이드바 상태를 만들거나 고치기 전에 반드시 먼저 불러온다.
---

# 성공의 열쇠 / 알아차림 리스트 규격

이 문서만 보고 처음부터 다시 만들어도 현재 코드와 **같은 결과**가 나와야 한다.
코드와 이 문서가 다르면 문서를 고치지 말고 먼저 사용자에게 어느 쪽이 맞는지 확인한다.

## 0. 작업 절차 (최우선, 매번 자동으로)

1. **시작 전 점검**: 이 문서를 읽고, 아래 "핵심 규칙"을 바꾸는 요청인지 확인한다. 바꾸는 요청이면 어떤 규칙이 바뀌는지 사용자에게 한 줄로 알린다.
2. **작업**: 규칙과 스타일(§6)을 지킨다.
3. **종료 후 검토**: 아래를 실행하고 결과를 그대로 보고한다.
   ```
   flutter analyze lib test
   flutter test
   ```
   기존 경고(main.dart의 `curly_braces_in_flow_control_structures`)만 남아야 한다(8개. goal_title_display.dart의 `viewportHeight` 경고는 2026-11-24에 없어짐).
4. **저장**: 규칙·규격이 바뀌었으면 이 문서를 갱신하고, `reference/` 사본을 lib의 현재 파일로 다시 복사한다.
   ```
   cp lib/services/list_file_service.dart lib/services/run_counter_service.dart lib/widgets/run_counter_panel.dart lib/services/item_text_style.dart .claude/skills/flow-list-sidebars/reference/
   ```
   Stop 훅(`.claude/hooks/list-sidebar-guard.sh`)이 테스트 실패, 사본 불일치, 문서 미갱신을 자동으로 잡는다.

## 1. 핵심 규칙: 두 리스트는 구조만 같은 별개 기능

**코드 구조 (2026-11-25 사용자 지시 "모듈화·코드 크기·실행 속도 최적화로 다시 만들되 결과는 완전히 동일")**: 두 사이드바 본체는 공용 파일 `lib/widgets/list_sidebar.dart` 하나다 — `ListSidebarItem`(항목), `ListSidebarSpec`(리스트마다 다른 값, `ListSidebarSpec.goal`·`.awareness` 상수), `ListSidebar<T extends ListSidebarItem>`(StatefulWidget 본체). `goal_list_sidebar.dart`·`awareness_list_sidebar.dart`는 바깥 이름(`GoalListSidebar`·`GoalItem`·`AwarenessListSidebar`·`AwarenessItem`)과 생성자를 그대로 둔 **얇은 StatelessWidget**으로, spec과 `newItem: GoalItem.new` 등만 넘긴다(🎯는 `onSelectItem`이 있을 때만 생김 = 끝장만). 예전에는 거의 같은 코드가 두 파일에 약 1,000줄씩 복사되어 있었다(이름만 바꾸면 937줄 같음). 합친 뒤 lib 코드 약 800줄 감소. 상태(항목·카운터·열린 파일·불러온 폴더)는 위젯 인스턴스마다 따로라 아래 "절대 공유하지 않는 것"은 그대로 지켜진다.
- `ListSidebarSpec` 값: kind, title, titleHint, itemHint, defaultFileName, logName(오류 로그), accent(끝장 blueAccent / 알아차림 orangeAccent — 제목 글자·항목 그라데이션·선택 테두리·순번 입력칸·접기 박스), panelAlpha(끝장 **220** / 알아차림 200), dockRight(끝장 true: 오른쪽에 붙고 왼쪽 가장자리 드래그·닫기 X는 오른쪽 끝 / 알아차림 false: 반대).
- 부모 알림은 두 리스트가 같은 묶음을 부른다(합칠 때 정리, 화면 결과 동일): 새로만들기 = onRunRecordsChanged·onFilePathChanged(null)·onTitleChanged('')·onItemsChanged·onSelectItem?('') / 저장 후 onFilePathChanged·onItemsChanged / 불러오기 setState 안 onFilePathChanged·onItemsChanged, 뒤에 onLoadDirectoryChanged·onRunRecordsChanged·onSelectItem?('') / 항목 추가 onItemsChanged / 삭제 onItemsChanged·onDeleteItem?('deleted'). main의 onGoalsChanged·onItemsChanged는 대입만 해서 더 불러도 화면이 같다.

| 항목 | 성공의 열쇠 (끝장 리스트) | 알아차림 리스트 |
|---|---|---|
| 위젯 | `GoalListSidebar` (`lib/widgets/goal_list_sidebar.dart`) | `AwarenessListSidebar` (`lib/widgets/awareness_list_sidebar.dart`) |
| `ListFileKind` | `goal` | `awareness` |
| 기본 폴더 | `문서\FlowSchedules` | `문서\FlowAwareness` |
| 제목 줄 | `[PJT]: 제목` | `[AWARE]: 제목` |
| 항목 블록 | `[GOAL:n]` … `[END_GOAL]` | `[AWARE_ITEM:n]` … `[END_AWARE_ITEM]` |
| 실행 카운터 줄 | `[RUN] 2026-11-12: 3` | `[AWARE_RUN] 2026-11-12: 3` |
| main.dart 카운터 | `_sidebarRunRecords` | `_awarenessRunRecords` |
| main.dart 열린 파일 | `_sidebarFilePath` | `_awarenessFilePath` |
| main.dart 불러온 폴더 | `_goalLoadDirectory` | `_awarenessLoadDirectory` |
| 사이드바 위치 | 화면 오른쪽 (`right: 0`), 왼쪽 가장자리 드래그 | 화면 왼쪽 (`left: 0`), 오른쪽 가장자리 드래그 |
| 제목 / 제목칸 힌트 | `📋성공의열쇠 시스템` / `오늘의 스케줄` | `👁️ 알아차림 리스트` / `오늘의 알아차림` |
| 항목 입력칸 힌트 | `할 일 입력...` | `내용 입력...` |
| 빈 파일명 기본값 | `미정_스케줄` | `미정_알아차림` |
| 항목 전송 | 🎯로 메인 화면 TopBar 목표 칸에 전송 (`onSelectGoal`) | 🎯로 **같은 목표 칸**에 전송 (`onSelectItem`, 2026-11-26 사용자 지시 "끝장 리스트와 동일하게") |

절대 공유하지 않는 것: 실행 카운터 Map, 열린 파일 경로, 불러온 폴더, 저장 폴더, 카운터 줄 접두어.
폴더 병합/복사 코드(예전 `sharedDirectory`, `importLegacyAwarenessFiles`)를 다시 만들지 않는다.

## 2. 저장·불러오기·새로만들기·폴더관리

각 사이드바의 작업 폴더 `_localPath` = `widget.loadDirectory`(존재할 때) → 없으면 `ListFileService.directoryFor(kind)`.

- **불러오기**: `FilePicker.platform.pickFiles(initialDirectory: ListFileService.pickerInitialDirectory(path), type: FileType.custom, allowedExtensions: ['txt'])`. 어떤 폴더의 txt든 열 수 있다. 열면 `ListFileService.parse(내용, kind: 자기 kind)`로 읽고, 카운터 Map을 `clear()` 후 `addAll`, `_currentFilePath`와 `onFilePathChanged`를 갱신하고, **`onLoadDirectoryChanged(file.parent.path)`**로 자기 리스트의 불러온 폴더만 기록한다.
- **저장** (2026-11-21 사용자 지시 "오늘의 할일 제목이 기존 파일 이름과 다르면 제목으로 새 파일, 기존 파일은 유지", 두 리스트 동일): `File(ListFileService.saveTargetPath(currentFilePath: _currentFilePath, directory: path, fileName: _safeFileName(제목).fileName))`. `ListFileService.serialize(kind: 자기 kind, …)`.
  - 열린 파일이 없으면 작업 폴더에 `'$path/$fileName'`으로 만든다.
  - 열린 파일 이름이 제목 파일명과 같으면(대소문자 무시, `제목 (n).txt`도 같은 제목) 그 파일에 덮어쓴다.
  - 제목이 다르면 **열린 파일과 같은 폴더**에 제목 이름으로 새 파일을 만들고 기존 파일은 건드리지 않는다. 저장 뒤 `_currentFilePath`는 새 파일이 된다.
  - 새로 만들 이름의 파일이 이미 있으면 덮어쓰지 않고 `제목 (2).txt`, `제목 (3).txt` …로 만든다(열린 파일이 없을 때도 같음).
  - 새 파일로 저장했으면 저장 완료 대화상자 끝에 `제목이 바뀌어 새 파일로 저장했습니다.
기존 파일은 그대로 있습니다:
<기존 경로>`를 붙인다(`_showSaveSuccessDialog(keptPath:)`).
- **새로만들기(`_clearAll`)**: 제목·항목·카운터·열린 파일 경로만 비운다. 불러온 폴더는 지우지 않는다. 그래서 그 뒤 저장은 그 리스트가 마지막으로 불러온 폴더(없으면 기본 폴더)에 새 파일로 된다.
- **폴더관리**: 열린 파일이 있으면 그 폴더, 없으면 `_localPath`를 `explorer.exe`로 연다.
- 파일명 규칙(`_safeFileName`): 금지문자 `<>:"/\|?*`와 제어문자는 ` x`로, 끝의 점·공백도 ` x`로 바꾸고, `.txt` 중복 제거, Windows 예약어(con, prn, aux, nul, com1-9, lpt1-9)나 빈 이름이면 §1의 기본 파일명으로 한다. 바뀐 문자는 저장 성공 대화상자에 알린다.

### Windows 파일 선택창 주의

file_picker 8.3.7의 Windows `pickFiles`는 `GetOpenFileNameW`를 쓴다. 시작 폴더 문자열이 앱이 처음 넘긴 값과 같으면 Windows가 그것을 무시하고 **앱 전체에서 마지막으로 연 폴더**를 보여준다. 그러면 다른 리스트에서 연 폴더가 나타나므로, 시작 폴더는 반드시 `ListFileService.pickerInitialDirectory()`(구분자 정규화 + 끝에 구분자)를 거쳐 넘긴다.

### 바깥 내용으로 리스트 파일 만들기 (2026-11-26 사용자 지시 "엑셀 단하나 시트를 '나는 ~이다!'로 정리해 알아차림 폴더에 '단하나' 파일로")

- 저장 폴더: 이 PC의 문서 폴더는 OneDrive라서 알아차림 = `C:\Users\yunyt\OneDrive\문서\FlowAwareness`, 끝장 = `…\OneDrive\문서\FlowSchedules`(`getApplicationDocumentsDirectory`). 같은 이름 파일이 있으면 덮어쓰기 전에 확인한다.
- 형식: `ListFileService.serialize`와 같다 — `[AWARE]: 제목` → 항목마다 `[AWARE_ITEM:n]` / 글 / `[END_AWARE_ITEM]`(카운터 줄은 없어도 됨), UTF-8, 줄바꿈 LF. python으로 만든 뒤 **앱의 `ListFileService.parse`로 읽히는지** 임시 테스트(`test/zz_tmp_…_test.dart`, 확인 후 삭제)로 검사한다.
- 엑셀이 열려 있으면 파일이 잠겨 openpyxl로 열 수 없다(PermissionError) → 복사본으로 읽는다. 쓰기는 Windows PowerShell 5(`powershell.exe` — pwsh 7에는 `Marshal.GetActiveObject`가 없음)로 실행 중인 Excel COM을 쓴다: `$wb.Saved`가 True일 때만 진행 → `SaveCopyAs(백업)` → 시트 `UsedRange.Clear()` → 2차원 배열로 한 번에 `Value2` → `Save()`. OneDrive 파일은 `$wb.FullName`이 https 주소라 `Join-Path`가 실패하므로 백업 경로는 PC 경로를 직접 쓴다. 한글이 든 .ps1은 UTF-8 **BOM**으로 저장한다. 긴 한국어·경로 문자열을 bash heredoc 안 python에 넣으면 `\U`·`\\`가 깨지므로 Write 도구로 .py 파일을 만든다.
- 정리 규칙(단하나): 위가 가장 높은 순위 → 겹치는 문장은 **처음 나온 위치**에 합친다. 모든 줄 `나는 … 이다!`(동사 문장은 `…하는 사람이다!`), 맞춤법은 고치고 URL·제목 줄(예: "성공한 사람들")은 빼거나 내용에 합친다. 결과: 원본 593행 → 178문장(엑셀 A=순위, B=문장). 원본 백업 `2026년_1조1H_Top Priority_단하나정리전_백업_20261126.xlsx`.

## 3. 상태 소유 (main.dart `_MainAreaState`)

```dart
final Map<String, int> _sidebarRunRecords = {}; // 끝장 리스트 실행 카운터 기록
final Map<String, int> _awarenessRunRecords = {}; // 알아차림 리스트 실행 카운터 기록 (끝장 리스트와 별개)
String _awarenessTitle = "";
String? _awarenessFilePath;
// 불러오기 폴더는 리스트별로 따로 기억한다 (서로 공유하지 않음)
String? _goalLoadDirectory;
String? _awarenessLoadDirectory;
```

`_buildGoalSidebar()`는 `runRecords: _sidebarRunRecords`, `loadDirectory: _goalLoadDirectory`, `onLoadDirectoryChanged: (v) => _goalLoadDirectory = v`를,
`_buildAwarenessSidebar()`는 `runRecords: _awarenessRunRecords`, `loadDirectory: _awarenessLoadDirectory`, `onLoadDirectoryChanged: (v) => _awarenessLoadDirectory = v`를 넘긴다.
두 사이드바 모두 `onRunRecordsChanged: () => setState(() {})`, `Positioned`에 고정 `ValueKey('goalSidebar')` / `ValueKey('awarenessSidebar')`, `onBringToFront`로 `_awarenessSidebarOnTop`을 토글한다.
상태는 앱 실행 중에만 유지된다(사이드바를 닫았다 열어도 유지, 앱 재시작 시 초기화).

사이드바 위젯 생성자에 추가되는 필드(두 위젯 동일):
```dart
/// 이 리스트에서 마지막으로 불러온 폴더 (다른 리스트와 공유하지 않음)
final String? loadDirectory;
final Function(String?) onLoadDirectoryChanged;
```
생성자 맨 앞에 `this.loadDirectory, required this.onLoadDirectoryChanged,`.

## 4. 서비스 파일 (정본 사본: `reference/`)

- `reference/list_file_service.dart`: `ListFileKind`(titleMarker, itemMarker, runLinePrefix, directoryName), `ListFileData`, `ListFileService.directoryFor / pickerInitialDirectory / saveTargetPath / serialize / parse`.
  - `serialize`: 제목 줄 → 카운터 줄들(날짜순, 0회 제외) → 항목 블록들.
  - `parse(content, kind:)`: 항목 블록과 예전 형식(`1. 항목`)을 모두 읽는다. 제목 줄은 `[PJT]`, `[AWARE]` 둘 다 인정한다. 자기 `runLinePrefix` 카운터 줄만 기록하고, 다른 리스트의 카운터 줄(`RunCounterService.isRunLine`)은 버린다(항목 텍스트로도 넣지 않음).
- `reference/run_counter_service.dart`: `defaultLinePrefix = '[RUN] '`, `maxCount = 99`, 줄 정규식 `^(\[[A-Z_]+\] )(\d{4}-\d{2}-\d{2}): (\d+)\s*$`, `todayKey`(yyyy-MM-dd), `isRunLine`, `parseLine(line, linePrefix:)`, `toLines(records, linePrefix:)`, `total`.
- `reference/run_counter_panel.dart` (2026-11-26 사용자 지시 "누적 외 박스 외곽으로 빼서 `실행` `과거 날짜` `누적+숫자`, 저장 누르면 날짜를 오늘로", 두 리스트 동일): 고정 크기 작은 박스(패딩 가로 8 세로 2, white 12 채움, white12 테두리, 모서리 10). **한 줄** `실행`(white70 13) → 8 → 저장 날짜 `MM.dd`(`RunCounterService.shortDate`, 흰색 13 굵게, 고정폭 숫자; `savedDate`가 null이면 날짜와 뒤 간격 없음) → 8 → `누적 N`(배지 박스 없음: `누적 ` 흰색 13 굵게, 숫자 amberAccent 17 w900) → 4 → 화살표 **세로 Column**(↑ amberAccent 툴팁 `오늘 실행 횟수 늘리기`, ↓ white54 `줄이기`). 예전(1.6.x)에는 `누적 N`을 amber 배지 박스(패딩 8/2, 모서리 8)가 감쌌다.
  - **저장 날짜 = 열린 파일의 마지막 수정 시각**(파일 형식은 바꾸지 않음 → 예전 파일도 바로 날짜가 보임). `ListSidebar`의 `_savedDate`: initState는 `_fileSavedDate(initialFilePath)`(lastModifiedSync), 불러오기는 `await file.lastModified()`, 저장 성공 뒤 `setState(_savedDate = DateTime.now())`, 새로만들기는 null. **접기·펼치기 파일 쓰기(`_setCollapsed`)는 쓰기 전 수정 시각을 읽어 `setLastModified`로 되돌린다**(저장이 아니므로 날짜가 바뀌면 안 됨). 방법 검토: A. 파일 수정 시각 / B. 파일에 `[SAVED]` 줄 추가 → A (형식·예전 파일 호환 그대로, 코드 적음).
  - 테스트: `fold_persist_test.dart`가 두 리스트 모두 실제 파일로 "열기 → `11.20` 보임 → 접기/펼치기 뒤에도 수정 시각 그대로 → 저장 → 오늘 날짜"를 검사, `run_counter_service_test.dart`가 `shortDate` 형식을 검사.
  - **화살표 멈춤** (2026-11-26 사용자 지시 "리스트 내용이 없거나 불러온 파일이 없으면 실적 누적 상·하 동작시키지 말 것", 두 리스트 동일): `RunCounterPanel(enabled:)`(기본 true). `ListSidebar._runCounterEnabled` = `_currentFilePath != null` **그리고** `_hasContent`(제목 또는 항목 글 중 공백 아닌 것이 하나라도). 멈추면 `_changeRunCount`가 바로 끝나고, InkWell onTap null, 아이콘 색 alpha `RunCounterPanel.disabledOpacity`(0.3), 두 화살표 툴팁 모두 `RunCounterPanel.disabledTooltip`(`리스트 파일을 불러오거나 저장한 뒤 쓸 수 있습니다`). 새 리스트는 저장하면(파일이 생기면) 켜진다. 항목 입력은 이미 setState하고, 제목은 리스너에서 `_hasContent`가 바뀔 때만 setState한다(`_lastHasContent`). 방법 검토: A. enabled 값으로 화살표 흐림·멈춤 / B. 콜백에서 값 되돌리기 → A. 테스트: `goal_list_sidebar_test` '두 리스트: 내용이나 파일이 없으면 실행 화살표가 멈춘다'(임시 파일 `tempListFile()`), 위치 검사 테스트는 파일이 없으므로 `find.byTooltip(disabledTooltip).first/.last`로 화살표를 찾는다.
  - 화살표는 `IconButton`이 아니라 `Tooltip`+`InkWell(모서리 4)`+`SizedBox(28×18)`+아이콘 20. 이유: IconButton은 최소 터치 크기 48로 늘어나 박스가 높아진다.
  - 오늘 횟수 숫자와 `오늘 실행` 글자는 **화면에 보이지 않는다**("'오늘 실행 1' 삭제하고 '실행' 글자로 변경"). 화살표는 오늘 횟수(0~99)를 바꾸고 결과는 누적 숫자로 보인다. 파일의 `[RUN] 날짜: n` 기록은 그대로.
  - 위젯 안에 LayoutBuilder·margin·FittedBox가 없다. 폭 맞춤은 부모(사이드바 제목 줄)의 FittedBox가 한다. 전달받은 Map만 수정한다.

- `reference/item_text_style.dart` (2026-11-25): 글자 서식 한 벌 `ItemTextStyle`(color RGB|null=흰색, sizeScale, bold, italic, underline, strike), `plain`, `palette`(E6B422 노랑·5CB85C 초록·E88AC4 분홍·A97FE0 보라·5BC0EB 하늘·9E9E9E 회색), `sizeSteps` 0.85/1.0/1.2/1.5와 `stepSize(현재, ±1)`, `apply(base)`, `toAttrs()`/`parseAttrs()`, 예전 `toLine()`/`parseLine()`(`[STYLE]`). 글자 구간 `StyleSpan(start, end, style)`(`[SPAN] s-e attrs`), `spansFromCharStyles`(같은 서식 이어진 구간, 기본 서식 제외)·`charStylesFromSpans`.
  - 파일 형식 (2026-11-25 사용자 지시 "글자 전체가 아니라 선택된 글자만"): 항목 블록 머리 다음(`[FOLDED]` 다음) 줄들에 `[SPAN] 2-4 color=E6B422;size=1.2;bold;italic;underline;strike` (Dart 문자열 위치, 끝 미포함)를 구간마다 한 줄. 서식 없는 항목은 줄이 없다. 예전 `[STYLE] …`(v1.4.0~1.4.1, 항목 전체)은 `StyleSpan(0, 글 길이)`로 읽는다. 항목 글 앞 공백을 잘라 읽으므로 잘린 만큼 구간을 당긴다. `ListFileData.spans`(List<List<StyleSpan>>), `serialize(spans:)`, `applyFoldState`는 디스크 구간을 그대로 보존한다.

처음부터 만들 때는 이 네 파일을 사본 그대로 쓴다.

## 5. 사이드바 화면 규격 (두 위젯 공통)

- **오토 레이아웃 크기** (2026-11-24 사용자 지시 "슬라이드 안의 텍스트 및 아이콘 오토레이아웃, 글자 작아짐, 불러온 리스트 박스 글자도 작아짐", 두 리스트 동일): 상태 필드 `double _uiScale`와 `_sz(base) => base * _uiScale`. build에서 `currentWidth`를 구한 직후 `_uiScale = (currentWidth / 480).clamp(0.7, 1.0)`. `_sz`를 쓰는 곳: 제목 입력칸 글자·힌트, 동작 버튼(아이콘 14·글자 12·패딩 12/8), 순번 원(radius 12·글자 12)·순번 입력칸(폭 40·글자 12), **항목 글자 14**(`_buildItemText`의 textStyle — 한 줄 넘는지 계산도 같은 크기라 접기 판단이 맞음), 접기 박스(24×20·아이콘 18), 도구 줄 `_iconBtn` 아이콘 18. 제목 줄은 FittedBox가 맞춘다. 기본 폭(화면 1280의 48% = 614)에서는 예전 크기 그대로.
- 기본 폭 화면의 48% (`_widthRatio = 0.48`), 최소 160(화면이 좁으면 기본 폭), 최대 화면 전체. 가장자리 15px 드래그 영역(`ListSidebar.edgeDragWidth`, `SystemMouseCursors.resizeLeftRight`)으로 폭 조절.
  - **스크롤바와 드래그 영역을 겹치지 않는다** (2026-11-28 사용자 지시 "알아차림 리스트 스크롤과 좌우 크기조정이 겹친다"): 데스크톱 스크롤바는 목록 오른쪽 끝에 붙는다. 알아차림(dockRight false)은 드래그 영역도 오른쪽이라 겹치므로, 항목 `ListView`를 `Padding(right: dockRight ? 0 : edgeDragWidth)`로 감싸 스크롤바를 드래그 영역 왼쪽으로 옮긴다. 끝장(드래그 왼쪽)은 겹치지 않아 그대로. 드래그 폭을 바꾸면 이 여백도 같은 상수라 함께 바뀐다.
- 바탕 `Colors.black.withAlpha(spec.panelAlpha)` (끝장 220, 알아차림 200 — 예전 코드 값 그대로), 안쪽 경계선 `Colors.white12` 1.5.
- 위에서부터: 제목 줄 → 제목 입력칸(orangeAccent, 굵게) → 버튼 `Wrap`(간격 8, 가운데) → `SizedBox(6)` → `Divider(white24, indent 20)` → 항목 `ListView`.
- **제목 줄** (2026-11-24 사용자 지시 "실행누적 박스를 슬라이드 제목 앞으로, 오토레이아웃"): 끝장 `[Expanded(Center(FittedBox(scaleDown, Row[RunCounterPanel, SizedBox(10), 제목]))), 닫기(X)]`, 알아차림 `[닫기(X), Expanded(같은 묶음)]`. 실행 박스와 제목을 **한 FittedBox로 묶어** 좁으면 함께 줄어든다. 예전 반대편 균형용 `SizedBox(40)`은 없앴다. 제목 글자 크기 `(짧은 변 * 0.03).clamp(11, 18)`.
- 버튼 순서와 색: 새로만들기(`Icons.note_add`, purpleAccent) · 저장(`Icons.save`, blueAccent) · 불러오기(`Icons.file_open`, greenAccent) · 폴더관리(`Icons.folder`, orangeAccent). `ElevatedButton.icon`, 배경 `color.withValues(alpha: 0.3)`, 아이콘 14, 글자 12 흰색, 모서리 8.
- **서식 툴박스** (2026-11-25 사용자 지시 "컬러·글자크기·중앙줄·언더바·기울기 툴박스를 첨부 이미지 2개 참조, 위치는 우측", 두 리스트 동일): 동작 버튼 줄을 `Row[ Expanded(버튼 Wrap), SizedBox(8), SizedBox(width: (160*_uiScale).clamp(0, (currentWidth-20)*0.3), FittedBox(scaleDown, centerRight, TextFormatToolbox)) ]`로 만든다. 폭을 30% 이하로 묶는 이유: flex 3:2로 나누면 기본 폭에서 버튼 4개가 두 줄로 밀린다.
  - **목록은 숨겨 두고 아이콘 버튼으로 연다** (2026-11-25 사용자 지시 "컬러 리스트, 글자 편집 리스트 아이콘 버튼을 만들어서 숨겨라", 두 리스트 동일): `TextFormatToolbox`는 StatefulWidget, 상태 `_showColors`·`_showFormat`(처음 둘 다 false, 따로 토글). 평소엔 오른쪽 정렬 `Row[ 🎨 palette_outlined(툴팁 `글자 색 목록 열기/닫기`, 고른 항목에 색이 있으면 아이콘이 그 색), 6, text_format(`글자 편집 목록 열기/닫기`) ]`만 보인다. 버튼 30×26, 모서리 6, 닫힘 2B2B2B·white12 테두리 / 열림 white 0.18·white38 테두리. 연 목록은 그 아래(간격 4) 색 칸 줄 → 편집 판 순서로 나온다. 여닫기는 항목을 고르지 않아도 되고, 흐림(0.45)·`서식을 바꿀 항목을 먼저 누르세요` 툴팁은 펼친 목록에만 붙는다.
  - `lib/widgets/text_format_toolbox.dart` `TextFormatToolbox(style, onChanged, scale)`: `style` = 선택 구간 첫 글자의 서식(null이면 선택 없음), `onChanged`는 **글자마다 적용할 함수** `ItemTextStyle Function(ItemTextStyle)`를 넘긴다(켜기/끄기 값은 첫 글자 기준으로 정함). 색 목록 줄 = 색 칸 22×22(팔레트 6색 + 진회색 444444=기본 흰색, 고른 칸에 검은 ✓, 툴팁 `글자 색`/`기본 색(흰색)`), 편집 판(2B2B2B, 모서리 8, white12 테두리) = `B`(굵게) · `format_italic`(기울임) · `format_underlined`(밑줄) · `format_strikethrough`(가운데 줄) · `text_decrease`(`글자 작게`) · `text_increase`(`글자 크게`). 켜진 버튼은 white 0.18 배경. 첨부 이미지의 목록(≡) 아이콘은 넣지 않았다.
  - 글자 크기는 **팝업 메뉴를 쓰지 않는다**(2026-11-25): 팝업은 입력칸 포커스를 빼앗아 드래그한 글자 선택이 풀린다(테스트에서 확인). 그래서 바로 누르는 A−/A+ 두 버튼으로 크기 단계를 옮긴다.
  - 대상 항목: 상태 `_styleTarget`(항목 **객체**). 항목 TextField를 `Focus(onFocusChange: 포커스 받으면 대상으로)`로 감싸고 `onTap`·접힌 글 누르기에서도 정한다(드래그 선택은 onTap이 안 불려서 Focus가 필요). 대상 항목 박스 테두리는 끝장 blueAccent / 알아차림 orangeAccent alpha 0.6, 나머지 white10. 툴박스는 `TextFieldTapRegion`(눌러도 입력칸 포커스·선택 유지) → `ListenableBuilder(listenable: 대상 controller ?? _noTarget)`(선택이 바뀌면 다시 그림)으로 감싼다. 글자를 선택하지 않으면 펼친 목록이 흐림(0.45)·눌리지 않음·툴팁 `서식을 바꿀 글자를 먼저 드래그해 선택하세요`. 새로만들기·불러오기는 `_styleTarget = null`, 대상 항목을 지우면 null.
  - 항목 클래스의 controller는 `StyledTextController`(`lib/widgets/styled_text_controller.dart`): 글자별 서식 `charStyles`(항상 글 길이와 같음), `spans` get/set, `lastRange`(지금 선택 또는 마지막으로 드래그한 구간 — 선택이 -1로 바뀌는 포커스 해제 때는 기억 유지, 커서만 옮기거나 글이 바뀌면 잊음), `styleAtRange()`, `applyToRange(edit)`, `styledSpan(base, displayText:)`, `buildTextSpan`(서식·한글 조합 밑줄 경계에서 나눔). `set value`에서 앞뒤 같은 부분을 비교해 바뀐 자리만 서식 목록을 늘리고 줄인다(새 글자는 바로 앞 글자 서식을 이어받음). `_buildItemText`의 textStyle은 기본(white, `_sz(14)`)이고, 한 줄 넘는지 계산과 접힌 글(`Text.rich`)은 `styledSpan`을 쓴다. 저장 `spans: 리스트.map((x) => x.controller.spans)`, 불러오기 `..controller.spans = data.spans[i]`. 서식은 **저장 버튼으로 파일에 남는다**.
- 패널을 누르면(`Listener.onPointerDown`) `onBringToFront`로 위에 올린다.

### 항목 박스 (`_buildBubbleItem`, 두 위젯 동일 — 2026-11-20 사용자 지시)

- 행: `_buildNumberBadge(index)` → `SizedBox(10)` → `Expanded(_buildItemText(항목, index))`. 박스 padding `fromLTRB(15, 5, 15, 5)`, 테두리 항상 `Colors.white10`.
- **항목 도구 줄** (2026-11-24 사용자 지시 "리스트 옆에 +,-,... 그룹 제거하고, 접기펴기 버튼 좌우에 배치", 두 리스트 동일): 예전 오른쪽 `more_vert`→펼침 묶음(↑↓🎯+−>)과 `_activeActionIndex`는 **없앴다. 다시 만들지 않는다.**
  `_buildItemText`의 Column 맨 위에 `_buildItemToolbar(항목, index, isLong)`을 **모든 항목에 항상** 둔다: `Row[ Expanded(FittedBox(scaleDown, centerRight, 왼쪽 묶음)), SizedBox(width 50, Center(_buildFoldBox(항목, isLong))), Expanded(FittedBox(scaleDown, centerLeft, 오른쪽 묶음)) ]`. 가운데 폭을 고정해 버튼 위치가 항목마다 같고, 좁은 폭에서는 양쪽 묶음만 줄어든다(넘침 없음).
  - 왼쪽: ↑ `arrow_upward`(orangeAccent, 툴팁 `위로 이동`, `_moveUp`) · ↓ `arrow_downward`(orangeAccent, `아래로 이동`, `_moveDown`) · 🎯(두 리스트) `gps_fixed`(greenAccent, `메인 화면으로 보내기`, `_sendToMain`). **켜짐/꺼짐 색** (2026-11-26 사용자 지적 "버튼이 눌러 있는지 알 수 없다, 설정 안 된 것은 더 어둡게"; 원인: 🎯가 항상 같은 greenAccent였고 사이드바는 메인에 무엇이 보내졌는지 몰랐음): main의 `_selectedSubGoal`을 `GoalListSidebar(selectedGoal:)` → `ListSidebar.selectedItem`으로 넘기고, `ListSidebar.sendSummary(항목 글)`(첫 줄, 12자 넘으면 `12자...` — `_sendToMain`이 보내는 값과 같은 함수)이 같으면 켜짐: 아이콘 `sendOnColor`(greenAccent) + `DecoratedBox` 배경 `sendOnBackground`(greenAccent 0.25, 모서리 8). 아니면 `sendOffColor`(greenAccent 0.3), 배경 투명. 같은 🎯를 다시 누르면 main이 ''로 바꿔 꺼진다.  방법 검토: A. main 선택값을 넘김 / B. 사이드바 안에 따로 상태 → A(메인에서 닫아도 바로 맞음, 상태 하나). 테스트: `goal_list_sidebar_test` '보낸 항목의 🎯만 밝고 나머지는 어둡다'.
  - **알아차림 🎯** (2026-11-26 사용자 지시, 첨부 그림의 끝장 🎯·날짜를 알아차림에도): `AwarenessListSidebar`에 `onSelectItem`·`onDeleteItem`(필수)·`selectedItem` 추가 → `ListSidebar`에 그대로 넘긴다(공용 코드라 🎯·켜짐/꺼짐 색 동일, 날짜는 원래 공용 `RunCounterPanel`이라 이미 있음). main은 목표 칸 하나(`_selectedSubGoal`)를 함께 쓰고 `_mainFromAwareness`로 어느 리스트에서 보냈는지 기억한다: `TopBar.sidebarGoals` = 보낸 리스트의 항목(`List<ListSidebarItem>`로 타입을 넓힘), 🎯 켜짐(`selectedGoal`/`selectedItem`)은 보낸 리스트에만 넘긴다. `_selectForMain(g, fromAwareness:)`: 같은 리스트의 같은 항목이면 끄고, 다르면 바꿈. 빈 값(새로만들기·불러오기)은 **그 리스트에서 보낸 것일 때만** 지운다(다른 리스트를 불러와도 목표 칸이 안 지워짐). `_deleteFromMain`도 같은 리스트일 때만. 방법 검토: A. 목표 칸 하나 공유 + 출처 기억 / B. 알아차림 전용 칸 새로 → A. 테스트 `알아차림 리스트: 🎯로 보내고, 보낸 항목만 밝다`.
  - 오른쪽: + `add_circle_outline`(blueAccent, `아래에 항목 추가`, `_addItem`) · − `remove_circle_outline`(white38, `항목 삭제`, `_handleDelete`).
  - `_iconBtn(icon, color, onPressed, tooltip)`: `IconButton` 아이콘 18, `constraints: BoxConstraints()`, padding 가로 6 세로 2.
- **순번 직접 변경**: 순번 `CircleAvatar`(radius 12, white24)를 `Tooltip('눌러서 순번 변경')`+`InkWell(CircleBorder)`로 감싼다. 누르면 그 자리가 폭 40 숫자 입력칸(`_numberController`/`_numberFocus`, `autofocus`, `digitsOnly`, 가운데 정렬, 글자 12, 채움 white24, 모서리 12, 테두리 끝장 blueAccent / 알아차림 orangeAccent)으로 바뀐다(`_numberEditIndex`).
  `_applyNumberEdit()`가 엔터(`onSubmitted`), 포커스 잃음(`_numberFocus` 리스너), **저장 버튼(`_saveToFile` 맨 앞)**에서 불린다: 입력값-1을 `0..길이-1`로 clamp해 `removeAt`/`insert`로 옮기고(나머지 순번은 자동으로 밀림), 숫자가 아니면 그대로 둔다. `onGoalsChanged`/`onItemsChanged` 호출. `_clearAll`은 `_numberEditIndex = null`.
  `dispose()`에서 리스너를 먼저 떼고 focus/controller를 해제한다(해제 중 setState 방지).
- **긴 항목 접기/펼치기**: 항목 클래스에 `bool collapsed = false`. **파일에 저장한다** (2026-11-21 사용자 지시 "접거나 펼친 상태 그대로 유지", 원인: 예전엔 화면 전용이라 다시 불러오면 모두 펼쳐졌음).
  - 파일 형식: 접힌 항목은 블록 머리 바로 다음 줄에 `[FOLDED]`(`ListFileService.foldedMarker`)를 둔다. 예: `[GOAL:1]` / `[FOLDED]` / 내용 / `[END_GOAL]`. 표시가 없으면 펼침(예전 파일 호환). `ListFileData.collapsed`(items와 같은 길이), `serialize(collapsed:)`.
  - 저장 버튼: `collapsed: 리스트.map((x) => x.collapsed).toList()`. 불러오기: `..collapsed = data.collapsed[i]`.
  - 접기/펼치기 버튼과 접힌 글 누르기는 `_setCollapsed(항목, 값)`을 부른다: setState 후 열린 파일(`_currentFilePath`)이 있으면 `ListFileService.applyFoldState(디스크 내용, kind:, screenItems: [(text:, collapsed:)])`로 **접힘 표시만** 바꿔 바로 쓴다(제목·항목·카운터는 디스크 그대로. 짝짓기: ① 같은 글끼리 화면 순서대로 ② 남은 항목(저장 전에 글을 고친 항목)은 같은 순번끼리 ③ 짝 없는 디스크 항목은 그대로). 파일 쓰기는 `_foldWrite = _foldWrite.then(...)`으로 순서대로 한다(빨리 여러 번 눌러도 마지막 상태가 남게). 그래서 저장 안 하고 앱을 꺼도 유지되고, 저장 안 한 편집은 파일에 섞이지 않는다.
  - 사용자 지적(2026-11-21 "저장 버튼을 누를 때만 유지된다"): 원인은 ① 글자만으로 짝지어 저장 전에 고친 항목의 접힘이 빠짐 ② 비동기 쓰기가 겹쳐 앞선 상태가 덮어씀. 위 ②·순차 쓰기로 고쳤다.
  - **검사 방법(사용자 지시)**: 실제 파일로 "A 열기 → 접기/펼치기(저장 안 함, 글 수정 포함) → B 열기 → A 다시 열기 → 상태 그대로"를 `test/fold_persist_test.dart`가 두 리스트 모두 검사한다. 가짜 파일 선택창은 `class _FakePicker extends FilePicker`(같은 토큰이라 `FilePicker.platform =` 가능), 실제 파일 IO는 `runAsync(delay)`+`pump`를 여러 번 반복해 기다린다(한 번으로는 불러오기가 안 끝남). 접은 뒤엔 `펼치기` 툴팁 순번이 바뀌므로 `at(i)`를 항목 순서로 다시 계산한다.
  - 앱 실행 중에는 main이 항목 객체를 보관하므로 사이드바를 닫았다 열어도 유지.
  **접기 박스 `_buildFoldBox`** (2026-11-24 사용자 지시 "접기 버튼은 가능하든 안 하든 사각형 박스로 아웃라인과 컬러 표시, 접기가 가능하면 그때 방향 모양"): 도구 줄 가운데 칸에 **모든 항목에 항상** 24×20 사각형(모서리 4)을 둔다. 색은 끝장 blueAccent / 알아차림 orangeAccent. 접을 수 있으면 채움 alpha 0.25·테두리 alpha 0.9(두께 1.2) + 안에 방향 아이콘(흰색 18) + `Tooltip`·`InkWell`로 눌림, 접을 수 없으면 채움 0.08·테두리 0.35, 아이콘·툴팁·눌림 없음.
  접을 수 있는지는 `_buildItemText`의 `LayoutBuilder`+`TextPainter(maxLines: 1, 글자 14 흰색)`로 **한 줄을 넘는지** 판단한다(`isLong`). 펼쳐진 상태 `Icons.keyboard_arrow_up`(^, 툴팁 `접기`), 접힌 상태 `Icons.keyboard_arrow_down`(v, 툴팁 `펼치기`).
  접힌 상태는 줄바꿈을 공백으로 바꾼 첫 줄 `Text(maxLines 1, ellipsis)`만 보이고, 글을 누르면 펼쳐진다. 입력 중(`onChanged`)에는 `setState`로 다시 그려 한 줄을 넘는 순간 버튼이 나타난다.

## 6. 코드 스타일

- 주석과 사용자에게 보이는 문구는 한국어. 주석은 "왜"를 적는다.
- `Platform.pathSeparator`로 경로를 만든다(저장 경로 조합의 기존 `'$path/$fileName'`은 유지).
- 두 사이드바의 동작·화면은 `list_sidebar.dart` 한 곳에서 고친다(자동으로 두 리스트 모두 바뀜). 리스트마다 달라야 하는 값은 `ListSidebarSpec`에 필드를 더하고 `.goal`·`.awareness` 두 상수에 값을 넣는다. 두 래퍼 파일에 기능 코드를 다시 넣지 않는다.
- 사용자가 한 리스트만 말해도 두 리스트에 함께 적용하고, **답변 첫 부분에 "끝장 리스트·알아차림 리스트 둘 다 적용"과 리스트별 확인 방법을 분명히 쓴다** (2026-11-21: 두 리스트에 다 적용했는데 답변이 끝장 리스트 위주라 사용자가 "알아차림 리스트도 동일하게 적용"을 다시 요청함).
- 리스트 종류에 따라 달라지는 값은 `ListFileKind`에 두고 하드코딩하지 않는다.
- `withOpacity` 대신 `withValues(alpha:)`.
- txt 파일은 UTF-8, 줄바꿈 `\n`.

## 7. 테스트 (반드시 통과)

- **리팩터링(동작은 그대로, 코드만 정리)일 때 픽셀 동일 검사** (2026-11-25): `integration_test/identity_snapshot_test.dart`가 실제 윈도우 앱으로 두 사이드바(기본·툴박스 펼침·순번 편집)와 상단바(보내기 전·후) 8장을 PNG로 찍는다(커서 깜빡임은 `EditableText.debugDeterministicCursor = true`로 고정 — 안 하면 커서 2px 선 때문에 가끔 다름). ① 바꾸기 전 코드로 `flutter test integration_test/identity_snapshot_test.dart -d windows --dart-define=OUT=build/identity_before` (이미 바꿨으면 `git stash push -q -- lib`로 잠시 되돌려 찍고 `git stash pop`) ② 바꾼 뒤 `OUT=build/identity_after` ③ `python tools/compare_snapshots.py build/identity_before build/identity_after` → `모두 같음`이어야 한다(다르면 `diff_<이름>.png`).

- `test/list_file_service_test.dart`: 종류별 왕복, 접힘 `[FOLDED]` 왕복·`applyFoldState`(디스크 제목/항목/카운터 유지)·예전 파일은 펼침, 폴더·카운터 줄 분리, 다른 리스트 카운터 무시, 예전 번호 형식 읽기, `pickerInitialDirectory` 정규화, `saveTargetPath`(같은 제목 덮어쓰기·다른 제목 새 파일·번호 붙이기·번호 붙은 파일 인정·특수문자·실제 파일 유지).
- `test/run_counter_service_test.dart`: 줄 생성/읽기, 일반 줄 무시, 접두어가 다른 줄 무시, `todayKey`.
- `test/list_file_service_test.dart` (2026-11-25): 두 리스트 `[SPAN]` 구간 왕복, 서식 없는 항목은 줄 없음, `applyFoldState` 후 구간 유지, 예전 `[STYLE]` 줄은 항목 전체 구간으로 읽힘.
- `test/fold_persist_test.dart`(2026-11-25 메모: 실제 파일 IO를 기다리는 테스트라 전체 테스트 중 PC가 바쁘면 가끔 `[true, false, true]` 대신 `[false]`로 실패한다. 이 파일만 다시 돌려 3번 통과하면 시간 문제다. 코드 탓으로 고치기 전에 먼저 따로 돌려 본다): 저장 없이 접기/펼치기 → 다른 파일 → 다시 열기 상태 유지(두 리스트, 실제 파일).
- `test/goal_list_sidebar_test.dart`: 알아차림 사이드바는 전달받은 카운터만 바꾼다, `실행` 글자만 보이고 오늘 숫자 없음·화살표가 `누적 N`(findRichText)을 바꿈, 실행 박스는 제목 왼쪽·저장 버튼 위·화살표 세로(누적 오른쪽)·높이 56 미만·360/768 폭 예외 없음, 폭 600 화면(사이드바 288)에서 항목 글자 14 미만·9.8 이상(두 리스트), 360/768/1280 폭에서 예외 없음, 순번 입력+엔터로 이동·범위 밖 번호는 맨 뒤, 긴 항목에만 접기/펼치기 버튼(두 리스트), 도구 줄(more_vert 없음·↑ 접기 왼쪽·+ 오른쪽·버튼 동작, 🎯는 끝장만), 접기 박스(24×20)는 모든 항목에 있고 방향 아이콘(크기 18 — 실행 카운터 화살표와 구분)은 긴 항목에만, 
- 테스트 추가 요령(2026-11-24): Dart 문자열의 `
`이 든 코드를 bash heredoc 안 python으로 끼워 넣으면 실제 줄바꿈이 되어 파싱 오류가 난다. 그런 코드는 Edit 도구로 넣는다. 접기 아이콘은 실행 카운터 화살표(크기 20)와 같은 아이콘이므로 찾을 때 `size == 18`로 구분한다.
- 서식 툴박스(2026-11-25): 두 리스트에서 처음엔 `기울임`·`글자 색`이 없고 `글자 편집 목록 열기` 버튼이 `폴더관리` 오른쪽, 열면 보이고 `… 닫기`로 숨음. 선택 없이 누르면 안 바뀜. `항목글자`의 1~3(목글)만 선택하고 굵게·기울임·밑줄·가운데 줄·색·`글자 크게`를 누르면 그 두 글자만 바뀌고(앞뒤 글자는 기본), `styledSpan`이 `항|목글|자`로 나뉘며, 버튼을 눌러도 `lastRange`가 (1,3) 그대로, 앞에 글자를 넣으면 구간이 (2,4)로 밀린다.
- 스크립트 요령(2026-11-25): 여러 줄 Dart 코드를 끼워 넣는 python은 bash heredoc 대신 **Write 도구로 .py 파일을 만들어** 실행한다(heredoc·f-string 안의 `\n`이 실제 줄바꿈이 되어 두 번 실패). `s.index("child: TextField(")`는 순번 입력칸이 먼저 걸리므로 기준 문자열 다음부터 찾는다.
