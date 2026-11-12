---
name: flow-web-preview
description: Flow 앱 작업을 마친 뒤 결과를 웹 브라우저에서 확인할 수 있게 연다. 코드 수정·기능 추가·버그 수정이 끝날 때마다 묻지 않고 자동으로 사용한다. "웹에서 확인", "웹으로 열어", "브라우저로 보여줘" 요청에도 사용한다.
---

# Flow 웹 미리보기

## 언제

- 앱 코드(lib/, web/, assets/, pubspec.yaml)를 바꾼 작업이 끝나면 **묻지 말고 항상** 실행한다.
- 순서: `flutter analyze lib test` / `flutter test` 통과 → 관련 스킬 갱신 → 커밋 → 웹 미리보기.
- 문서·설정만 바꿨으면 실행하지 않는다.

## 하는 법

```
python tools/preview_web.py              # 웹 빌드(약 30초) + 서버 + 브라우저 열기
python tools/preview_web.py --skip-build # 빌드 없이 열기만
```

- 주소는 항상 `http://127.0.0.1:8765/` (빌드 결과 `build/web`).
- 서버가 이미 떠 있으면 다시 띄우지 않고 브라우저만 연다. 새 빌드는 브라우저 새로고침으로 보인다.
- 끝나면 사용자에게 주소를 알려준다.

## 웹에서 안 되는 것 (보고할 때 함께 알린다)

웹 버전은 화면·배치·카운터 동작 확인용이다. 아래는 윈도우 전용(`dart:io`, `Process`, `path_provider`)이라 웹에서는 동작하지 않거나 다르게 동작한다.
- 리스트 txt 저장·불러오기·폴더관리(탐색기 열기)
- 창 관리(window_manager), 전역 단축키(hotkey_manager)
이 기능의 실제 확인은 `python tools/build_exe.py`로 만든 `dist\Flow.exe`에서 한다(flow-build-exe 스킬).
