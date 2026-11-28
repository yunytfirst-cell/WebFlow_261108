---
name: flow-skill-record
description: Flow 프로젝트에서 skill(.claude/skills) 기록 규칙과 자동 점검 훅. 모든 작업 끝에 사용자가 말하지 않아도 적용한다. 사용자가 불편·문제·지적을 말했을 때, "skill에 저장", "기록해", 훅(.claude/hooks, settings.json)을 고칠 때 먼저 불러온다.
---

# skill 기록 규칙 (명령 없어도 항상)

사용자 지시: 2026-11-12 "skill에 계속 기록하고 있지?", 2026-11-21 "내가 명령하지 않아도, skill에 저장해라".

## 작업 전: 이해한 내용을 먼저 확인받는다 (2026-11-28 사용자 지시 "내가 명령한 내용을 먼저 너가 이해한 내용을 나에게 확인 후 명령을 실행해라")

- 적용 범위(사용자 선택): **앱 코드·skill·설정을 바꾸는 요청만**. 질문 답, "실행"(앱 띄우기), 설명 요청은 바로 한다.
- 방법: 코드를 고치기 전에 `AskUserQuestion` 하나로 "제가 이해한 내용: 무엇을 / 지금 어디(상태) → 어디(상태)로 / 화면에서 어떻게 보이게 / 손대지 않는 것"을 쓰고, 선택지는 `맞다, 진행` + 그럴듯한 다른 해석 1~2개(사용자는 Other로 고쳐 쓸 수 있음). 코드를 읽어야 이해가 정해지면 먼저 읽기만 하고(수정 없음) 그다음 묻는다.
- 사용자가 맞다고 하면 그 뒤(방법 2개 비교·수정·analyze/test·skill 기록·버전·커밋·push·앱 실행)는 **묻지 않고 끝까지** 한다. 방법 고르기는 여전히 내가 직접 한다(아래 절).
- 왜: 2026-11-28 "스크롤을 현재 위치에서 좌측으로 이동"을 "오른쪽 여백 15px"로 잘못 이해해 v1.7.6을 만들고, "확인 후 실행"을 "앱 띄우기 전 테스트 확인"으로 잘못 이해했다 → 같은 일을 두 번 하고 버전이 두 번 더 올라갔다.

## 수정 전: 빠르고 쉬운 방법 2개 이상 비교 → 바로 진행 (2026-11-25 사용자 지시, 항상)

사용자 지시: "수정 전 빠르고 쉬운 방법을 2개 이상 검토 후에 쉽고 빠르게 변경할 수 있는 방법으로 진행해라. 수정 전 항상 적용해라. 내가 말하거나 선택하지 않아도 너가 직접 해라. 단지 화면에 어떤 방법으로 했는지 표시만 해라."

- 코드·설정·skill을 고치기 **전마다** 방법을 2개 이상 떠올려 "얼마나 쉽고 빠른가(바꿀 곳 수, 위험, 확인 시간)"로 비교하고, 가장 쉽고 빠른 것을 **스스로 골라 바로** 진행한다. 사용자에게 고르라고 묻지 않는다(AskUserQuestion 금지 — 요구 자체가 두 뜻으로 읽힐 때만 예외).
- 답변(작업 중 첫 메시지와 최종 답변)에 짧게 표시한다:
  `방법 검토: A. … / B. … → A 선택 (이유 한 줄)`
- 계기(원인): 2026-11-25 "글자 중앙 맞춤"에서 글자 쪽을 고치려고 테스트 환경 재현·Strut·OverflowBox를 차례로 시도하다 12분을 썼고, 사용자가 "그냥 아이콘 위치만 변경하면 안되나?"라고 지적했다. 처음에 "글자를 옮기기 vs 아이콘을 옮기기"를 비교했으면 바로 아이콘 이동(바꿀 곳 2줄)을 골랐을 것이다.
- 비교 기준 예: 화면 배치 문제는 "보이는 쪽(아이콘·여백) 값 하나 바꾸기"가 "글꼴·레이아웃 원리 고치기"보다 대개 빠르다. 같은 결과면 바꾸는 파일·줄이 적은 쪽.

### 단, skill 규칙·기본 원칙은 어기지 않는다 (2026-11-25 사용자 지시 "빠르고 쉬운 방법으로 하지만 skill의 규칙을 어기면 안 된다. 예시: 모듈화 기본원칙… 등등")

- 순서: ① 관련 SKILL.md 규칙 확인 → ② 빠른 방법 2개 이상 → ③ **규칙을 어기는 방법은 후보에서 뺀다** → ④ 남은 것 중 가장 쉽고 빠른 것. 빠르더라도 규칙을 어기면 고르지 않는다.
- 답변 표시에 규칙 확인도 한 마디 넣는다: `방법 검토: A. … / B. … → A 선택 (이유, 규칙 OK)`. 규칙 때문에 뺀 방법이 있으면 `(B는 ○○ 규칙 위반이라 제외)`.
- 기본 원칙 (어기면 안 되는 것, 모든 수정에 적용):
  1. **모듈화**: 한 기능은 한 파일·한 위젯/서비스에 둔다. 새 기능이 크면 새 파일(`lib/widgets/…`, `lib/services/…`)로 나누고, 남의 파일에 끼워 넣지 않는다(예: 서식 툴박스 `text_format_toolbox.dart`, 글자별 서식 `styled_text_controller.dart`, 깃발 아이콘 `finish_flag_icon.dart`). 두 곳에 같은 코드를 복사하지 말고 공용 위젯·함수로 만든다(예외: flow-list-sidebars §6처럼 두 사이드바를 같은 위치·같은 이름으로 대칭 유지하는 규칙).
  2. **값은 이름 붙은 상수로**: 비율·크기·시간은 `static const`(예: `TopBarTicker.slideDuration`, `GoalTitleDisplay.iconDropRatio`)로 두고 왜 그 값인지 주석. 리스트 종류별 값은 `ListFileKind`에(하드코딩 금지).
  3. **기존 동작·데이터 호환**: 예전 저장 파일이 그대로 열려야 한다(예: `[STYLE]` → `[SPAN]` 바뀌어도 예전 줄 읽기). 사용자가 정한 규칙(예: 모드·테마 간격 70, STEP 박스 위치 고정)은 새 요청이 직접 바꾸라고 하지 않으면 유지.
  4. **두 리스트 함께**: 끝장·알아차림 리스트는 한쪽만 말해도 둘 다 같은 방식으로(flow-list-sidebars §6).
  5. **검토 절차 생략 금지**: `flutter analyze lib test`(기존 경고 8개만), `flutter test` 통과, 바꾼 파일만 `dart format`(포맷 안 된 top_bar·ticker는 format 금지) — 2026-11-26 `dart format lib test integration_test`로 폴더 전체를 돌려 관계없는 30개 파일이 바뀐 일이 있었다. 반드시 파일 이름을 하나씩 적고, main.dart·top_bar.dart처럼 원래 포맷 안 된 파일은 format하지 않는다(실수했으면 `git diff > 백업.patch` 후 관계없는 파일만 `git restore 파일명…`으로 되돌리고 내 수정만 다시 넣는다), 버전·CHANGELOG·태그, skill 기록, 커밋·push, 앱 실행. "빠르게"라도 이 단계는 빼지 않는다.
  6. **주석·문구는 한국어**, 주석은 "왜"를 적는다. `withOpacity` 대신 `withValues(alpha:)`.
  7. **코드 크기 최적화** (2026-11-25 사용자 지시 "모듈화, 코드사이즈 최적화, 실행속도 최적화 점검"): 같은 코드를 늘리지 않는다(두 번 쓰면 함수·공용 위젯으로). 쓰지 않게 된 코드·import·주석 처리된 옛 코드·임시 디버그 출력(`debugPrint('DBG`)은 그 작업에서 지운다. 임시 측정 파일(`test/_tmp/`)은 커밋 전에 지운다. 에셋은 필요한 크기로(예: 과녁 PNG는 바깥 여백을 잘라 정사각형 222px). 새 패키지는 꼭 필요할 때만(이유를 skill에 적음, 예: `integration_test`는 실제 앱 픽셀 검사용 dev 의존성).
  8. **실행 속도 최적화** (같은 지시): 매 프레임·매 build마다 무거운 일을 하지 않는다 — 텍스트 측정(`TextPainter`)·파일 읽기·목록 다시 만들기는 값이 바뀔 때만(예: TopBar `_flattenedLines` 캐시, `_measureIconsRow`는 0.5px 넘게 바뀔 때만 setState). 애니메이션은 바뀌는 부분만 다시 그린다(`TweenAnimationBuilder`·`ListenableBuilder` 범위를 좁게). 바뀌지 않는 위젯은 `const`. 파일 IO는 `async`로, 연속 쓰기는 순서대로 묶는다(`_foldWrite = _foldWrite.then(...)`). `setState`는 필요한 위젯 범위에서만.
  9. **오토레이아웃** (2026-11-25 사용자 지시 "오토레이아웃 점검 skill 포함"): 화면 요소는 창 크기·윈도우 글자 크기(이 PC 130%)가 바뀌어도 넘치거나 창 밖으로 나가지 않아야 한다.
     - 만들 때: 고정 픽셀 대신 부모 폭·높이나 기준 글자 크기에 비례(예: 사이드바 `_uiScale = (폭/480).clamp(0.7, 1.0)`과 `_sz()`, 목표바 글자 `_barWidth*0.045`, 아이콘 = 박스 높이 × 비율). 한 줄에 여러 요소는 `FittedBox(scaleDown)`·`Expanded`·`Flexible`·`Wrap`으로 좁으면 줄거나 줄바꿈. 비율·최솟값은 이름 붙은 상수(원칙 2). 박스보다 큰 아이콘은 `OverflowBox`로 넘치게 하되 다른 요소와 겹치지 않게(상단바 테스트가 겹침 검사).
     - 점검: `test/auto_layout_test.dart` — 창 800×600·1024×700·1280×800·1920×1080·2560×1440 × 글자 100·130·160%에서 상단바(보내기 전·후)와 두 리스트 사이드바를 그려 넘침 예외 없음, 설정 아이콘·저장 버튼·서식 툴박스 버튼이 창 안에 있는지 본다. **새 화면 요소를 만들거나 크기·배치를 바꾸면 이 테스트에 그 요소를 추가**하고 통과시킨다(`flutter test`에 포함되어 매 작업 자동 실행). 실제 글꼴에서의 위치는 `integration_test/top_bar_center_test.dart -d windows`(flow-top-bar).
     - 테스트 요령: 마퀴(흐르는 글) 타이머가 남으면 "A Timer is still pending"으로 실패하니 테스트 끝에 `pumpWidget(SizedBox())` 후 `pump(10초)`. 창 크기는 `tester.view.physicalSize` + `devicePixelRatio = 1`, 글자 크기는 `MediaQueryData(textScaler: TextScaler.linear(1.3))`.
     - 기록: 2026-11-25 처음 점검 시 현재 화면은 모든 조합 통과.
- **"결과는 완전히 동일하게" 정리할 때** (2026-11-25): 바꾸기 전에 실제 앱 화면을 PNG로 찍고(flow-list-sidebars §7의 `identity_snapshot_test.dart`), 바꾼 뒤 다시 찍어 `tools/compare_snapshots.py`로 `모두 같음`을 확인한다. 단위 테스트 통과만으로 "동일"이라고 하지 않는다. 기록: 2026-11-25 두 리스트 사이드바를 공용 `list_sidebar.dart`로 합침(약 800줄 감소), 주석 처리된 옛 코드 16줄 삭제 — 8장 모두 같음.
- **점검 시점**: 코드를 고친 작업마다 커밋 전에 `git diff`를 보며 7·8·9번을 확인한다(9번은 `test/auto_layout_test.dart` 통과)(중복 코드, 남은 디버그·임시 파일, build 안의 무거운 계산, 불필요한 setState). 문제를 찾으면 그 작업 안에서 고치고, 답변의 방법 검토 줄에 `규칙 OK`로 표시한다. 큰 정리(기존 코드 전체 최적화)는 사용자가 요청할 때 따로 한다.
- 이 목록에 없는 규칙은 해당 작업의 SKILL.md(표 참고: CLAUDE.md Skills)가 정한다. 시작 전에 그 SKILL.md를 grep해 관련 줄을 확인한다.

## 무엇을 저장하나

작업이 끝날 때마다, 아래 중 하나라도 있으면 맞는 `.claude/skills/*/SKILL.md`에 적는다. 묻지 않는다.
- 새로 정한 규칙·규격·숫자 (예: 창은 가장 작은 모니터의 90% 안)
- 사용자가 지적하거나 불편을 말한 점 → **원인과 다시 안 생기게 하는 규칙**
- 내가 한 번에 못 하고 다시 고친 점 → 처음부터 맞게 하는 확인 방법
- 더 빠른 방법, 디버깅 명령

맞는 skill이 없으면 새 skill 폴더를 만들고 `CLAUDE.md`의 Skills 표에 한 줄 추가한다. skill만 보고 같은 결과를 처음부터 다시 만들 수 있어야 한다.

## skill·코드에 글을 끼워 넣을 때 (2026-11-25, 같은 실수 4번)

- bash heredoc 안 python 문자열에 백슬래시가 들어가면 깨진다: Windows 경로 `build\windows\x64\runner\Release\flow.exe`의 `\x`·`\r`·`\f`가 제어문자로 바뀌어 `build\windowsdunner\Releaselow.exe`처럼 되거나, `\x`가 문법 오류를 낸다. Dart의 `'\n'`도 실제 줄바꿈이 된다.
- 그래서: 짧은 추가·수정은 **Edit 도구**, 긴 코드 수정은 **Write 도구로 .py 파일을 만들어** 실행한다. skill에 경로를 쓸 때는 슬래시(`build/windows/...`)로 쓴다.
- 쓴 뒤 제어문자 검사: `python -c "s=open('파일',encoding='utf-8').read(); print([hex(ord(c)) for c in s if ord(c)<32 and c not in chr(10)+chr(9)])"` → `[]`이어야 한다.
- 재발 2026-11-28: 빌드 기록에 `%TEMP%\flowcheck`를 heredoc python 일반 문자열로 넣어 `\f`가 깨짐(위 규칙을 어김). **skill에 한 줄 추가는 무조건 Edit 도구**로 한다(경로가 없어 보여도).

## 답변에 보고

답변 끝 부분에 "skill 저장: `<skill 이름>` — 무엇" 한 줄. 사용자가 "저장하고 있지?"라고 묻게 만들지 않는다.

## 자동 점검 (훅)

| 훅 | 파일 | 하는 일 |
|---|---|---|
| UserPromptSubmit | `.claude/hooks/list-sidebar-reminder.sh` | 요청마다 이 규칙을 상기 문구로 넣음 |
| Stop | `.claude/hooks/skill-record-guard.sh` | 앱 코드(`lib/ windows/ tools/ pubspec.yaml`)가 커밋 안 된 변경 또는 마지막 커밋(HEAD)에서 바뀌었는데 `.claude/skills/`는 안 바뀌었으면 종료를 한 번 막음 (두 번째는 메시지만, 무한 반복 방지) |
| Stop | `.claude/hooks/list-sidebar-guard.sh` | 리스트 관련 파일 변경 시 테스트·reference 사본·SKILL.md 점검 (flow-list-sidebars) |

- 정말 기록할 규칙이 없었으면 커밋 메시지에 `[skill-ok] <이유>`를 넣으면 통과한다.
- 훅 시험: 임시 git 저장소(scratchpad)에 `lib/a.dart`만 커밋하고 `echo '{}' | CLAUDE_PROJECT_DIR=<임시> bash .claude/hooks/skill-record-guard.sh` → `decision: block`이 나와야 한다.
- 훅을 고치면 `bash .claude/hooks/list-sidebar-reminder.sh | python -c "import json,sys; json.load(sys.stdin)"`로 JSON이 깨지지 않았는지 확인한다.
- 훅 `.sh`는 LF 줄끝으로 둔다(`.gitattributes`의 `*.sh text eol=lf`). CRLF가 섞이면 bash가 `\r` 때문에 깨질 수 있다.

## 더 빠른 방법 (작업하며 배운 것)

- 여러 파일을 한꺼번에 문자열 치환할 때는 bash heredoc 안 `python -` 대신 **scratchpad에 .py 파일을 Write로 만들어 실행**한다. heredoc 안 파이썬 문자열에서는 Dart의 `r'[/\]'`, `\n` 같은 역슬래시가 깨져 치환이 실패한다(2026-11-21 두 번 실패). 2026-11-26에도 `'\\n'`처럼 두 번 써도 실제 줄바꿈이 되어 두 번 또 실패했다 — **Dart 코드에 `\n`이 들어가면 heredoc을 쓰지 말고 처음부터 Edit 도구**로 넣는다. 같은 날 `<<'EOF'`(따옴표 heredoc)·`sed -i`의 `\\F`도 역슬래시가 사라졌다 — 이 Bash 도구에서는 **역슬래시가 하나라도 들어가는 스크립트·치환은 Write로 .py 파일을 만들어 실행하거나 Edit 도구**를 쓴다. 파일은 `open(..., newline='')`로 써서 줄끝을 바꾸지 않는다.
- 한글 바로 앞 문자열 보간은 `${sep}월` 대신 `$sep월`로 쓴다(Dart 식별자는 ASCII라 lint `unnecessary_brace_in_string_interps`가 난다).
