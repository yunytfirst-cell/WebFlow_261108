---
name: flow-run-app
description: Flow 앱 작업을 마친 뒤 사용자가 직접 확인할 수 있게 앱(윈도우 데스크톱)을 실행해 화면에 띄운다. 코드 수정·기능 추가·버그 수정이 끝날 때마다 묻지 않고 자동으로 사용한다. "실행해", "화면에 보여줘", "띄워", "확인하게 해줘" 요청에도 사용한다.
---

# Flow 앱 실행해서 화면에 띄우기

사용자가 말하는 "확인할 수 있게 보여줘 / 웹으로 확인"은 **앱을 실제로 실행해서 화면에 띄우라는 뜻**이다. 브라우저 웹 빌드가 아니다.

## 언제

- 앱 코드(lib/, assets/, pubspec.yaml, windows/)를 바꾼 작업이 끝나면 **묻지 말고 항상** 실행한다.
- 순서: `flutter analyze lib test` / `flutter test` 통과 → 관련 스킬 갱신 → 커밋 → 앱 실행.
- 문서·설정만 바꿨으면 실행하지 않는다.

## 하는 법

```
python tools/run_app.py              # 릴리스 빌드(약 25초) 후 실행
python tools/run_app.py --skip-build # 빌드 없이 바로 실행
```

- 이미 떠 있는 개발용 Flow(`build\windows\x64\runner\Release\flow.exe`)는 닫고 새로 띄운다. 빌드 중 exe가 잠기는 것을 막기 위해서다. 배포용 `dist\Flow.exe`로 실행 중인 창은 건드리지 않는다.
- 끝나면 "앱을 화면에 띄웠다"와 무엇을 확인하면 되는지(바뀐 기능, 눌러볼 버튼)를 짧게 알려준다.
- 실행만 했고 내가 직접 조작해 보지 않았으면 그렇다고 말한다.

## 참고

- 배포용 단일 exe는 flow-build-exe 스킬(`python tools/build_exe.py`).
- 웹 빌드(`tools/preview_web.py`)는 사용자가 명시적으로 "브라우저/웹 빌드"를 요청할 때만 쓴다. 웹에서는 저장·불러오기·폴더관리·창 관리·단축키가 동작하지 않는다.
