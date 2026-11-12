# Flow (FlowWork)

윈도우용 Flutter 집중·스케줄 앱. 성공의 열쇠(끝장 리스트)와 알아차림 리스트, 타이머, 실행 카운터가 있다.

## 제 1원칙 (2026-11-12 사용자 지시, 모든 규칙보다 먼저)

**skill을 시작 전, 끝난 뒤 항상 검사하고 기록한다. 말하지 않아도 한다.** 시작 전에는 아래 표에서 맞는 SKILL.md를 다시 열고 관련 줄을 grep으로 확인한다. 끝난 뒤에는 `flutter analyze lib test`, `flutter test`로 검토하고 새로 정한 규칙·절차를 SKILL.md에 기록한다.

## 작업이 끝나면 (묻지 말고 이 순서로)

1. `flutter analyze lib test` / `flutter test` 통과 (기존 경고 9개만 남아야 함)
2. 관련 SKILL.md 갱신 (규격이 바뀌었으면 reference 사본도)
3. 커밋 → 현재 작업 브랜치를 `origin`(GitHub `yunytfirst-cell/WebFlow_261108`)에 push. main에 직접 push·병합은 먼저 확인.
4. `python tools/run_app.py`로 앱을 실행해 화면에 띄우고, 무엇을 확인하면 되는지 알려준다.

## Skills (.claude/skills/)

| 작업 | Skill |
| --- | --- |
| 성공의 열쇠·알아차림 리스트, 실행 카운터, 저장·불러오기·새로만들기·폴더 | `flow-list-sidebars` |
| 앱 실행해서 화면에 띄우기 (작업 끝날 때마다) | `flow-run-app` |
| 배포용 실행파일(dist/Flow.exe) 만들기 | `flow-build-exe` |

맞는 skill이 없으면 새로 만들고 이 표에 추가한다.

## 자동 점검 (.claude/settings.json 훅)

- 요청마다: 위 원칙을 상기시키는 문구를 넣는다 (`.claude/hooks/list-sidebar-reminder.sh`).
- 작업 종료 시: 리스트 관련 파일이 바뀌었으면 테스트, reference 사본 일치, SKILL.md 갱신 여부를 검사한다 (`.claude/hooks/list-sidebar-guard.sh`).
