#!/usr/bin/env bash
# UserPromptSubmit 훅: 매 요청마다 최우선 규칙을 Claude 컨텍스트에 넣는다.
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"[최우선 규칙] 성공의 열쇠(끝장 리스트)·알아차림 리스트·실행 카운터·리스트 저장/불러오기/새로만들기/폴더, 또는 lib/main.dart의 사이드바 상태를 다루는 작업이면 코드를 보기 전에 flow-list-sidebars 스킬을 먼저 불러 점검하고, 끝나면 flutter analyze/test로 검토한 뒤 규칙이 바뀌었으면 SKILL.md와 reference 사본에 저장한다. 사용자가 말하지 않아도 항상 한다."}}
JSON
