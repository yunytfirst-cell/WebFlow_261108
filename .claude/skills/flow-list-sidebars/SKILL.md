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
   기존 경고(main.dart의 `curly_braces_in_flow_control_structures`, goal_title_display.dart의 `viewportHeight`)만 남아야 한다.
4. **저장**: 규칙·규격이 바뀌었으면 이 문서를 갱신하고, `reference/` 사본을 lib의 현재 파일로 다시 복사한다.
   ```
   cp lib/services/list_file_service.dart lib/services/run_counter_service.dart lib/widgets/run_counter_panel.dart .claude/skills/flow-list-sidebars/reference/
   ```
   Stop 훅(`.claude/hooks/list-sidebar-guard.sh`)이 테스트 실패, 사본 불일치, 문서 미갱신을 자동으로 잡는다.

## 1. 핵심 규칙: 두 리스트는 구조만 같은 별개 기능

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
| 항목 전송 | 🎯로 메인 화면 TopBar에 전송 (`onSelectGoal`) | 전송 기능 없음 |

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
- `reference/run_counter_panel.dart` (2026-11-24 사용자 지시 3번 반영): 고정 크기 작은 박스(패딩 가로 8 세로 2, white 12 채움, white12 테두리, 모서리 10). **한 줄** `실행`(white70 13) → `누적 N` 배지(글자 13/17, 패딩 가로 8 세로 2, 모서리 8, amber) → 화살표 **세로 Column**(↑ amberAccent 툴팁 `오늘 실행 횟수 늘리기`, ↓ white54 `줄이기`).
  - 화살표는 `IconButton`이 아니라 `Tooltip`+`InkWell(모서리 4)`+`SizedBox(28×18)`+아이콘 20. 이유: IconButton은 최소 터치 크기 48로 늘어나 박스가 높아진다.
  - 오늘 횟수 숫자와 `오늘 실행` 글자는 **화면에 보이지 않는다**("'오늘 실행 1' 삭제하고 '실행' 글자로 변경"). 화살표는 오늘 횟수(0~99)를 바꾸고 결과는 누적 숫자로 보인다. 파일의 `[RUN] 날짜: n` 기록은 그대로.
  - 위젯 안에 LayoutBuilder·margin·FittedBox가 없다. 폭 맞춤은 부모(사이드바 제목 줄)의 FittedBox가 한다. 전달받은 Map만 수정한다.

처음부터 만들 때는 이 세 파일을 사본 그대로 쓴다.

## 5. 사이드바 화면 규격 (두 위젯 공통)

- 기본 폭 화면의 48% (`_widthRatio = 0.48`), 최소 160(화면이 좁으면 기본 폭), 최대 화면 전체. 가장자리 15px 드래그 영역(`SystemMouseCursors.resizeLeftRight`)으로 폭 조절.
- 바탕 `Colors.black.withAlpha(200)`, 안쪽 경계선 `Colors.white12` 1.5.
- 위에서부터: 제목 줄 → 제목 입력칸(orangeAccent, 굵게) → 버튼 `Wrap`(간격 8, 가운데) → `SizedBox(6)` → `Divider(white24, indent 20)` → 항목 `ListView`.
- **제목 줄** (2026-11-24 사용자 지시 "실행누적 박스를 슬라이드 제목 앞으로, 오토레이아웃"): 끝장 `[Expanded(Center(FittedBox(scaleDown, Row[RunCounterPanel, SizedBox(10), 제목]))), 닫기(X)]`, 알아차림 `[닫기(X), Expanded(같은 묶음)]`. 실행 박스와 제목을 **한 FittedBox로 묶어** 좁으면 함께 줄어든다. 예전 반대편 균형용 `SizedBox(40)`은 없앴다. 제목 글자 크기 `(짧은 변 * 0.03).clamp(11, 18)`.
- 버튼 순서와 색: 새로만들기(`Icons.note_add`, purpleAccent) · 저장(`Icons.save`, blueAccent) · 불러오기(`Icons.file_open`, greenAccent) · 폴더관리(`Icons.folder`, orangeAccent). `ElevatedButton.icon`, 배경 `color.withValues(alpha: 0.3)`, 아이콘 14, 글자 12 흰색, 모서리 8.
- 패널을 누르면(`Listener.onPointerDown`) `onBringToFront`로 위에 올린다.

### 항목 박스 (`_buildBubbleItem`, 두 위젯 동일 — 2026-11-20 사용자 지시)

- 행: `_buildNumberBadge(index)` → `SizedBox(10)` → `Expanded(_buildItemText(항목, index))`. 박스 padding `fromLTRB(15, 5, 15, 5)`, 테두리 항상 `Colors.white10`.
- **항목 도구 줄** (2026-11-24 사용자 지시 "리스트 옆에 +,-,... 그룹 제거하고, 접기펴기 버튼 좌우에 배치", 두 리스트 동일): 예전 오른쪽 `more_vert`→펼침 묶음(↑↓🎯+−>)과 `_activeActionIndex`는 **없앴다. 다시 만들지 않는다.**
  `_buildItemText`의 Column 맨 위에 `_buildItemToolbar(항목, index, isLong)`을 **모든 항목에 항상** 둔다: `Row[ Expanded(FittedBox(scaleDown, centerRight, 왼쪽 묶음)), SizedBox(width 50, Center(_buildFoldBox(항목, isLong))), Expanded(FittedBox(scaleDown, centerLeft, 오른쪽 묶음)) ]`. 가운데 폭을 고정해 버튼 위치가 항목마다 같고, 좁은 폭에서는 양쪽 묶음만 줄어든다(넘침 없음).
  - 왼쪽: ↑ `arrow_upward`(orangeAccent, 툴팁 `위로 이동`, `_moveUp`) · ↓ `arrow_downward`(orangeAccent, `아래로 이동`, `_moveDown`) · (끝장만) 🎯 `gps_fixed`(greenAccent, `메인 화면으로 보내기`, `_sendToMain`).
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
- 같은 일을 하는 두 사이드바 코드는 대칭으로 유지한다. 한쪽을 고치면 다른 쪽도 같은 위치·같은 이름으로 고친다(단, §1의 차이는 유지).
- 사용자가 한 리스트만 말해도 두 리스트에 함께 적용하고, **답변 첫 부분에 "끝장 리스트·알아차림 리스트 둘 다 적용"과 리스트별 확인 방법을 분명히 쓴다** (2026-11-21: 두 리스트에 다 적용했는데 답변이 끝장 리스트 위주라 사용자가 "알아차림 리스트도 동일하게 적용"을 다시 요청함).
- 리스트 종류에 따라 달라지는 값은 `ListFileKind`에 두고 하드코딩하지 않는다.
- `withOpacity` 대신 `withValues(alpha:)`.
- txt 파일은 UTF-8, 줄바꿈 `\n`.

## 7. 테스트 (반드시 통과)

- `test/list_file_service_test.dart`: 종류별 왕복, 접힘 `[FOLDED]` 왕복·`applyFoldState`(디스크 제목/항목/카운터 유지)·예전 파일은 펼침, 폴더·카운터 줄 분리, 다른 리스트 카운터 무시, 예전 번호 형식 읽기, `pickerInitialDirectory` 정규화, `saveTargetPath`(같은 제목 덮어쓰기·다른 제목 새 파일·번호 붙이기·번호 붙은 파일 인정·특수문자·실제 파일 유지).
- `test/run_counter_service_test.dart`: 줄 생성/읽기, 일반 줄 무시, 접두어가 다른 줄 무시, `todayKey`.
- `test/fold_persist_test.dart`: 저장 없이 접기/펼치기 → 다른 파일 → 다시 열기 상태 유지(두 리스트, 실제 파일).
- `test/goal_list_sidebar_test.dart`: 알아차림 사이드바는 전달받은 카운터만 바꾼다, `실행` 글자만 보이고 오늘 숫자 없음·화살표가 `누적 N`(findRichText)을 바꿈, 실행 박스는 제목 왼쪽·저장 버튼 위·화살표 세로(누적 오른쪽)·높이 56 미만·360/768 폭 예외 없음, 360/768/1280 폭에서 예외 없음, 순번 입력+엔터로 이동·범위 밖 번호는 맨 뒤, 긴 항목에만 접기/펼치기 버튼(두 리스트), 도구 줄(more_vert 없음·↑ 접기 왼쪽·+ 오른쪽·버튼 동작, 🎯는 끝장만), 접기 박스(24×20)는 모든 항목에 있고 방향 아이콘(크기 18 — 실행 카운터 화살표와 구분)은 긴 항목에만, 
- 테스트 추가 요령(2026-11-24): Dart 문자열의 `
`이 든 코드를 bash heredoc 안 python으로 끼워 넣으면 실제 줄바꿈이 되어 파싱 오류가 난다. 그런 코드는 Edit 도구로 넣는다. 접기 아이콘은 실행 카운터 화살표(크기 20)와 같은 아이콘이므로 찾을 때 `size == 18`로 구분한다.
