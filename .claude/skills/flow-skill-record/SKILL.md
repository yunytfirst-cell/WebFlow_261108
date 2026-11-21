---
name: flow-skill-record
description: Flow 프로젝트에서 skill(.claude/skills) 기록 규칙과 자동 점검 훅. 모든 작업 끝에 사용자가 말하지 않아도 적용한다. 사용자가 불편·문제·지적을 말했을 때, "skill에 저장", "기록해", 훅(.claude/hooks, settings.json)을 고칠 때 먼저 불러온다.
---

# skill 기록 규칙 (명령 없어도 항상)

사용자 지시: 2026-11-12 "skill에 계속 기록하고 있지?", 2026-11-21 "내가 명령하지 않아도, skill에 저장해라".

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
