#!/usr/bin/env bash
# Stop 훅: 성공의 열쇠 / 알아차림 리스트 관련 파일이 바뀌었으면
#  1) 관련 테스트 실행  2) reference 사본 일치 확인  3) SKILL.md 갱신 여부 확인
# 문제가 있으면 decision:block 으로 Claude가 고치고 스킬에 저장하게 한다.
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
input=$(cat)
case "$input" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) active=1 ;; *) active=0 ;; esac

skill=.claude/skills/flow-list-sidebars
guarded="lib/main.dart lib/services/list_file_service.dart lib/services/run_counter_service.dart lib/widgets/run_counter_panel.dart lib/widgets/goal_list_sidebar.dart lib/widgets/awareness_list_sidebar.dart test/list_file_service_test.dart test/run_counter_service_test.dart test/goal_list_sidebar_test.dart"

changed=$(git status --porcelain -- $guarded 2>/dev/null | awk '{print $NF}')
[ -z "$changed" ] && exit 0

problems=""

# 1) 테스트
if ! out=$(flutter test test/list_file_service_test.dart test/run_counter_service_test.dart test/goal_list_sidebar_test.dart 2>&1); then
  problems="${problems}- 리스트 관련 flutter test 실패:\n$(printf '%s' "$out" | tail -n 15)\n"
fi

# 2) reference 사본 일치
for f in lib/services/list_file_service.dart lib/services/run_counter_service.dart lib/widgets/run_counter_panel.dart; do
  if ! diff -q --strip-trailing-cr "$f" "$skill/reference/$(basename "$f")" >/dev/null 2>&1; then
    problems="${problems}- $f 가 $skill/reference 사본과 다름: 규격 변경이면 SKILL.md 갱신 후 사본 다시 복사\n"
  fi
done

# 3) 바뀐 파일이 SKILL.md보다 새로우면 문서 검토 필요
for f in $changed; do
  if [ -f "$f" ] && [ "$f" -nt "$skill/SKILL.md" ]; then
    problems="${problems}- $f 가 SKILL.md 이후에 수정됨: 규칙/규격 변경을 SKILL.md에 반영(변경 없으면 SKILL.md를 검토 후 저장)\n"
  fi
done

[ -z "$problems" ] && exit 0

msg="[flow-list-sidebars 자동 점검] 종료 전에 해결하세요:\n${problems}"
if [ "$active" = 1 ]; then
  # 이미 한 번 막았으면 무한 반복을 피하고 사용자에게만 알린다
  python -c 'import json,sys; print(json.dumps({"systemMessage": sys.argv[1]}, ensure_ascii=False))' "$(printf "$msg")"
else
  python -c 'import json,sys; print(json.dumps({"decision":"block","reason": sys.argv[1]}, ensure_ascii=False))' "$(printf "$msg")"
fi
exit 0
