#!/usr/bin/env bash
# UserPromptSubmit 훅: 매 요청마다 최우선 규칙을 Claude 컨텍스트에 넣는다.
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"[최우선 규칙] 성공의 열쇠(끝장 리스트)·알아차림 리스트·실행 카운터·리스트 저장/불러오기/새로만들기/폴더, 또는 lib/main.dart의 사이드바 상태를 다루는 작업이면 코드를 보기 전에 flow-list-sidebars 스킬을 먼저 불러 점검하고, 끝나면 flutter analyze/test로 검토한 뒤 규칙이 바뀌었으면 SKILL.md와 reference 사본에 저장한다. 사용자가 말하지 않아도 항상 한다. 또한 앱 코드를 바꾼 작업이 끝나면 묻지 말고 검토·스킬 갱신·커밋·GitHub push(현재 작업 브랜치, main 직접 push 금지) 후 python tools/run_app.py로 앱을 실행해 화면에 띄우고, 무엇을 확인하면 되는지 알려준다(flow-run-app 스킬). 사용자가 말하는 \"웹으로 확인\"은 앱 실행을 뜻한다."}}
JSON
