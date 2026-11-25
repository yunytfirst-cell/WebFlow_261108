---
name: flow-skill-record
description: Flow 프로젝트에서 skill(.claude/skills) 기록 규칙과 자동 점검 훅. 모든 작업 끝에 사용자가 말하지 않아도 적용한다. 사용자가 불편·문제·지적을 말했을 때, "skill에 저장", "기록해", 훅(.claude/hooks, settings.json)을 고칠 때 먼저 불러온다.
---

# skill 기록 규칙 (명령 없어도 항상)

사용자 지시: 2026-11-12 "skill에 계속 기록하고 있지?", 2026-11-21 "내가 명령하지 않아도, skill에 저장해라".

## 수정 전: 빠르고 쉬운 방법 2개 이상 비교 → 바로 진행 (2026-11-25 사용자 지시, 항상)

사용자 지시: "수정 전 빠르고 쉬운 방법을 2개 이상 검토 후에 쉽고 빠르게 변경할 수 있는 방법으로 진행해라. 수정 전 항상 적용해라. 내가 말하거나 선택하지 않아도 너가 직접 해라. 단지 화면에 어떤 방법으로 했는지 표시만 해라."

- 코드·설정·skill을 고치기 **전마다** 방법을 2개 이상 떠올려 "얼마나 쉽고 빠른가(바꿀 곳 수, 위험, 확인 시간)"로 비교하고, 가장 쉽고 빠른 것을 **스스로 골라 바로** 진행한다. 사용자에게 고르라고 묻지 않는다(AskUserQuestion 금지 — 요구 자체가 두 뜻으로 읽힐 때만 예외).
- 답변(작업 중 첫 메시지와 최종 답변)에 짧게 표시한다:
  `방법 검토: A. … / B. … → A 선택 (이유 한 줄)`
- 계기(원인): 2026-11-25 "글자 중앙 맞춤"에서 글자 쪽을 고치려고 테스트 환경 재현·Strut·OverflowBox를 차례로 시도하다 12분을 썼고, 사용자가 "그냥 아이콘 위치만 변경하면 안되나?"라고 지적했다. 처음에 "글자를 옮기기 vs 아이콘을 옮기기"를 비교했으면 바로 아이콘 이동(바꿀 곳 2줄)을 골랐을 것이다.
- 비교 기준 예: 화면 배치 문제는 "보이는 쪽(아이콘·여백) 값 하나 바꾸기"가 "글꼴·레이아웃 원리 고치기"보다 대개 빠르다. 같은 결과면 바꾸는 파일·줄이 적은 쪽.

## 무엇을 저장하나

작업이 끝날 때마다, 아래 중 하나라도 있으면 맞는 `.claude/skills/*/SKILL.md`에 적는다. 묻지 않는다.
- 새로 정한 규칙·규격·숫자 (예: 창은 가장 작은 모니터의 90% 안)
- 사용자가 지적하거나 불편을 말한 점 → **원인과 다시 안 생기게 하는 규칙**
- 내가 한 번에 못 하고 다시 고친 점 → 처음부터 맞게 하는 확인 방법
- 더 빠른 방법, 디버깅 명령

맞는 skill이 없으면 새 skill 폴더를 만들고 `CLAUDE.md`의 Skills 표에 한 줄 추가한다. skill만 보고 같은 결과를 처음부터 다시 만들 수 있어야 한다.

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

- 여러 파일을 한꺼번에 문자열 치환할 때는 bash heredoc 안 `python -` 대신 **scratchpad에 .py 파일을 Write로 만들어 실행**한다. heredoc 안 파이썬 문자열에서는 Dart의 `r'[/\]'`, `\n` 같은 역슬래시가 깨져 치환이 실패한다(2026-11-21 두 번 실패). 파일은 `open(..., newline='')`로 써서 줄끝을 바꾸지 않는다.
- 한글 바로 앞 문자열 보간은 `${sep}월` 대신 `$sep월`로 쓴다(Dart 식별자는 ASCII라 lint `unnecessary_brace_in_string_interps`가 난다).
