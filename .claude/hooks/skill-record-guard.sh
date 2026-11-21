#!/usr/bin/env bash
# Stop 훅: 앱 코드(lib/ windows/ pubspec.yaml tools/)가 바뀌었는데 .claude/skills가 함께 바뀌지 않았으면
# 종료를 한 번 막고 skill에 기록하게 한다. (사용자 지시 2026-11-21 "내가 명령하지 않아도 skill에 저장해라")
# 검사 대상: 커밋 안 된 변경 + 마지막 커밋(HEAD).
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
input=$(cat)
case "$input" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) active=1 ;; *) active=0 ;; esac

app_re='^(lib/|windows/|tools/|pubspec\.yaml$)'
skill_re='^\.claude/skills/'

problems=""

# 1) 커밋 안 된 변경
wt=$( { git diff --name-only HEAD 2>/dev/null; git ls-files --others --exclude-standard 2>/dev/null; } | sort -u)
if printf '%s\n' "$wt" | grep -Eq "$app_re" && ! printf '%s\n' "$wt" | grep -Eq "$skill_re"; then
  problems="${problems}- 커밋 안 된 앱 코드 변경이 있는데 .claude/skills 변경이 없음: $(printf '%s\n' "$wt" | grep -E "$app_re" | head -5 | tr '\n' ' ')\n"
fi

# 2) 마지막 커밋
head_files=$(git show --name-only --format= HEAD 2>/dev/null)
if printf '%s\n' "$head_files" | grep -Eq "$app_re" && ! printf '%s\n' "$head_files" | grep -Eq "$skill_re"; then
  # 직전 커밋 메시지에 [skill-ok] 가 있으면 (검토했지만 기록할 규칙이 없었음) 통과
  if ! git log -1 --format=%B | grep -q '\[skill-ok\]'; then
    problems="${problems}- 마지막 커밋 $(git log -1 --format=%h)이 앱 코드를 바꿨는데 skill 갱신이 없음\n"
  fi
fi

[ -z "$problems" ] && exit 0

msg="[skill 기록 자동 점검] 사용자가 말하지 않아도 skill에 저장한다:\n${problems}→ 새 규칙·사용자가 고쳐 준 점·원인·더 빠른 방법을 맞는 .claude/skills/*/SKILL.md에 적고(없으면 새 skill + CLAUDE.md 표 추가) 커밋·push. 정말 기록할 것이 없으면 커밋 메시지에 [skill-ok]와 이유를 쓴다."
if [ "$active" = 1 ]; then
  python -c 'import json,sys; print(json.dumps({"systemMessage": sys.argv[1]}, ensure_ascii=False))' "$(printf "$msg")"
else
  python -c 'import json,sys; print(json.dumps({"decision":"block","reason": sys.argv[1]}, ensure_ascii=False))' "$(printf "$msg")"
fi
exit 0
