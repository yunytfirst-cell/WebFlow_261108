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
- **저장**: `File(_currentFilePath ?? '$path/$fileName')`. 불러온 파일이 있으면 그 파일에 덮어쓰고, 없으면 작업 폴더에 `_safeFileName(제목)` 이름으로 새로 만든다. `ListFileService.serialize(kind: 자기 kind, …)`.
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

- `reference/list_file_service.dart`: `ListFileKind`(titleMarker, itemMarker, runLinePrefix, directoryName), `ListFileData`, `ListFileService.directoryFor / pickerInitialDirectory / serialize / parse`.
  - `serialize`: 제목 줄 → 카운터 줄들(날짜순, 0회 제외) → 항목 블록들.
  - `parse(content, kind:)`: 항목 블록과 예전 형식(`1. 항목`)을 모두 읽는다. 제목 줄은 `[PJT]`, `[AWARE]` 둘 다 인정한다. 자기 `runLinePrefix` 카운터 줄만 기록하고, 다른 리스트의 카운터 줄(`RunCounterService.isRunLine`)은 버린다(항목 텍스트로도 넣지 않음).
- `reference/run_counter_service.dart`: `defaultLinePrefix = '[RUN] '`, `maxCount = 99`, 줄 정규식 `^(\[[A-Z_]+\] )(\d{4}-\d{2}-\d{2}): (\d+)\s*$`, `todayKey`(yyyy-MM-dd), `isRunLine`, `parseLine(line, linePrefix:)`, `toLines(records, linePrefix:)`, `total`.
- `reference/run_counter_panel.dart`: "오늘 실행" 숫자(amberAccent, 26/30) + 위/아래 화살표(툴팁 `오늘 실행 횟수 늘리기`/`줄이기`, 0~99), "누적 N" 배지. 폭 320 미만이면 세로 배치. 전달받은 Map만 수정한다.

처음부터 만들 때는 이 세 파일을 사본 그대로 쓴다.

## 5. 사이드바 화면 규격 (두 위젯 공통)

- 기본 폭 화면의 48% (`_widthRatio = 0.48`), 최소 160(화면이 좁으면 기본 폭), 최대 화면 전체. 가장자리 15px 드래그 영역(`SystemMouseCursors.resizeLeftRight`)으로 폭 조절.
- 바탕 `Colors.black.withAlpha(200)`, 안쪽 경계선 `Colors.white12` 1.5.
- 위에서부터: 닫기(X) + 가운데 제목(`FittedBox`, 글자 크기 `(짧은 변 * 0.03).clamp(11, 18)`) → 제목 입력칸(orangeAccent, 굵게) → 버튼 `Wrap`(간격 8, 가운데) → `RunCounterPanel` → `Divider(white24, indent 20)` → 항목 `ListView`.
- 버튼 순서와 색: 새로만들기(`Icons.note_add`, purpleAccent) · 저장(`Icons.save`, blueAccent) · 불러오기(`Icons.file_open`, greenAccent) · 폴더관리(`Icons.folder`, orangeAccent). `ElevatedButton.icon`, 배경 `color.withValues(alpha: 0.3)`, 아이콘 14, 글자 12 흰색, 모서리 8.
- 패널을 누르면(`Listener.onPointerDown`) `onBringToFront`로 위에 올린다.

## 6. 코드 스타일

- 주석과 사용자에게 보이는 문구는 한국어. 주석은 "왜"를 적는다.
- `Platform.pathSeparator`로 경로를 만든다(저장 경로 조합의 기존 `'$path/$fileName'`은 유지).
- 같은 일을 하는 두 사이드바 코드는 대칭으로 유지한다. 한쪽을 고치면 다른 쪽도 같은 위치·같은 이름으로 고친다(단, §1의 차이는 유지).
- 리스트 종류에 따라 달라지는 값은 `ListFileKind`에 두고 하드코딩하지 않는다.
- `withOpacity` 대신 `withValues(alpha:)`.
- txt 파일은 UTF-8, 줄바꿈 `\n`.

## 7. 테스트 (반드시 통과)

- `test/list_file_service_test.dart`: 종류별 왕복, 폴더·카운터 줄 분리, 다른 리스트 카운터 무시, 예전 번호 형식 읽기, `pickerInitialDirectory` 정규화.
- `test/run_counter_service_test.dart`: 줄 생성/읽기, 일반 줄 무시, 접두어가 다른 줄 무시, `todayKey`.
- `test/goal_list_sidebar_test.dart`: 알아차림 사이드바는 전달받은 카운터만 바꾼다, 오늘 실행 표시와 화살표, 360/768/1280 폭에서 예외 없음.
