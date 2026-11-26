---
name: flow-build-exe
description: Flow 앱의 윈도우 실행파일(exe)을 만들거나, 빌드·배포·패키징(dist/Flow.exe, Enigma Virtual Box, .evb) 방법을 바꿀 때 먼저 불러온다. "실행파일 만들어", "exe 만들어", "빌드해", "배포 파일" 같은 요청에 사용한다.
---

# Flow 실행파일 만들기

## 하는 법 (이것만 실행한다)

```
python tools/build_exe.py              # 빌드 + 폴더형 + 단일 exe (약 20초)
python tools/build_exe.py --skip-build # 이미 빌드된 결과로 묶기만
```
사용자는 `tools\build_exe.bat`을 더블클릭해도 된다. 새로 스크립트를 짜거나 예전 `.evb`를 손으로 고치지 않는다.

- **bat 파일 규칙** (2026-11-26 사용자 지적: 더블클릭하자 `'��릭' is not recognized` 오류): 원인은 bat의 한국어 주석이 UTF-8 + LF 줄끝이라 cmd(CP949로 읽음)가 줄을 잘못 나눠 주석 일부를 명령으로 실행한 것. **bat은 ASCII만, CRLF 줄끝**으로 쓴다. `.gitattributes`에 `*.bat text eol=crlf`. 한국어 설명은 py 파일에 둔다.
- **빌드 전 실행 중인 개발용 앱 닫기** (같은 날 지적: `LNK1104: cannot open file ...Release\flow.exe`): 원인은 작업 끝마다 run_app.py로 띄운 `build\...\Release\flow.exe`가 떠 있어 링커가 exe를 덮어쓰지 못한 것. `run_flutter_build()`가 `run_app.close_running()`을 불러 build 폴더 flow.exe만 닫는다(dist\Flow.exe는 그대로). 첫 빌드가 실패하면 **한 번 자동으로 다시** 빌드한다(C1083·잠금 해제 지연, flow-run-app과 같은 현상).
- 검사: 개발용 앱을 띄운 상태에서 `cmd //c "tools\\build_exe.bat < nul"` → `> 실행 중이던 Flow 종료`, 빌드·묶기 성공, 빈 폴더로 복사한 dist\Flow.exe 창 제목 `Flow v1.7.3` (2026-11-26).

## 결과물

| 경로 | 설명 |
|---|---|
| `dist\Flow.exe` | 단일 실행파일 (약 16MB). 이 파일 하나로 실행 |
| `dist\Flow\flow.exe` | 폴더형. 같은 폴더의 dll·`data`와 함께 실행 |
| `dist\flow_build.evb` | 매번 새로 만드는 Enigma 설정 (손대지 않음) |

`dist/`, `build/`는 git에 올리지 않는다(.gitignore).

버전: exe 파일 속성(파일 버전)과 창 제목은 `pubspec.yaml` 버전을 따른다. 배포 전에 버전이 올라가 있는지 확인한다(flow-versioning). 결과 보고에 버전을 함께 적는다.

## 스크립트 규칙 (`tools/build_exe.py`)

1. `flutter build windows --release` → `build\windows\x64\runner\Release`.
2. Release를 `dist\Flow`로 복사. `dist\Flow\data`는 지우고 새로 복사한다. Release에 섞인 예전 패키징 파일(`*.evb`, `flow_single*`)은 복사·패키징에서 뺀다. VC++ 런타임(`msvcp140.dll`, `vcruntime140.dll`, `vcruntime140_1.dll`)이 없으면 System32에서 복사한다.
3. Enigma 설정(.evb)은 **매번 현재 `dist\Flow` 파일 목록으로 새로 생성**한다. 예전 `dist\flow_single.evb`, `dist\flow_release.evb`는 파일 목록이 옛 빌드에 고정되어 있어 쓰지 않는다. 입력 `dist\Flow\flow.exe`, 출력 `dist\Flow.exe`, 파일 압축 켬, 레지스트리 가상화 끔.
4. `C:\Program Files (x86)\Enigma Virtual Box\enigmavbconsole.exe <evb>`로 묶고, 출력에 `successfully saved`가 없으면 실패로 끝낸다.

## 사용자가 Enigma 창으로 직접 묶은 exe 오류 (2026-11-26 사용자 지적 "단일 실행파일 만들고 폴더 이동 후 실행하면 `Cannot load library audioplayers_windows_plugin.dll` 팝업, 전에는 문제 없었다")

- 원인: 사용자가 Enigma 창에서 `build\windows\x64\runner\Release\enigma.evb`(2026-11-25 저장, 사용자 파일)로 `flow_single.exe`를 만들었다. 이 설정은 ① 파일 목록이 그때 Release 폴더에 고정(예전 `flow_single_*.exe`까지 넣음 — 11-25 결과가 1GB), ② VC++ 런타임(msvcp140·vcruntime140·vcruntime140_1) 없음, ③ 압축 끔. 그런데 11-26 결과는 14.5MB로 flutter_windows.dll·app.so 등 필요한 파일이 실제로는 다 들어가지 않았다. **Release 폴더 안에서 실행하면 빠진 dll을 옆의 진짜 파일로 찾아 문제가 안 보이다가**, 바탕화면으로 옮기면 dll이 없어 팝업이 뜬다("전에는 괜찮았다"의 이유).
- 확인: 두 exe를 빈 폴더로 복사해 실행 → 사용자 `flow_single.exe`는 바로 종료, `dist\Flow.exe`(스크립트)는 창 제목 `Flow v1.7.3`으로 정상.
- 해결: Enigma 창·예전 `.evb`를 쓰지 말고 **`tools\build_exe.bat`(= `python tools/build_exe.py`)의 `dist\Flow.exe`를 옮겨 쓴다**. 스크립트는 매번 현재 `dist\Flow` 목록으로 evb를 새로 만들고 VC++ 런타임도 넣는다.
- 단일 exe 검사는 항상 **빌드 폴더가 아닌 빈 폴더로 복사해서** 실행한다(빌드 폴더에서는 빠진 파일이 가려진다).
- "바탕화면으로 복사해서 실행" 요청: `dist\Flow.exe` → `C:\Users\yunyt\OneDrive\Desktop\Flow-vX.Y.Z.exe`(사용자 파일 `flow_single.exe`를 덮어쓰지 않게 버전 이름). 보고에 **어디서(전체 경로) → 어디로** 복사했는지 둘 다 적는다(2026-11-26 사용자 질문 "어디에서 복사한거지?" — 받는 곳만 적었었음).

## 앱 아이콘 (2026-11-24 사용자 지적 "실행파일 아이콘이 너무 작아 안 보인다, 노란 메모 아이콘처럼 크고 잘 보이게")

- 원인: 예전 아이콘은 어두운 남색 바탕에 얇은 노란 링이라, 작업표시줄·바탕화면 크기에서 검은 동그라미처럼 보였다.
- 지금: `python tools/make_icon.py`가 `windows/runner/resources/app_icon.ico`(16·24·32·48·64·128·256)와 미리보기 `tools/app_icon_preview.png`를 만든다. 칸을 거의 꽉 채우는(여백 1%, 모서리 12%) **노란 그라데이션 사각형** + 진한 남색 굵은 링(위쪽 열림) + 굵은 위쪽 화살표. 16·24px은 링을 빼고 화살표만 더 굵게.
- 아이콘을 손으로 그리지 말고 이 스크립트 값을 고친 뒤 → 미리보기 이미지를 열어 작은 크기까지 확인 → `python tools/build_exe.py`.
- 탐색기가 예전 아이콘을 캐시해 보여주면 `ie4uinit.exe -show`를 실행하거나 exe를 다른 이름으로 복사해 본다.

## GitHub에 올리기 ("실행파일 만들고 github에 저장해라", 2026-11-24)

- exe는 git에 커밋하지 않는다(`dist/`는 .gitignore, 저장소가 커짐). **GitHub Release의 첨부파일**로 올린다. 저장소 `yunytfirst-cell/WebFlow_261108`는 **PUBLIC**이라 누구나 내려받을 수 있다는 점을 보고에 적는다.
- `gh`는 로그인되어 있지 않다(`gh auth status` 실패). git push에 쓰는 저장된 자격증명을 토큰으로 쓴다(화면에 찍지 않는다):
  ```
  export GH_TOKEN=$(printf "protocol=https
host=github.com

" | git credential fill | sed -n 's/^password=//p')
  cp dist/Flow.exe <스크래치>/Flow-vX.Y.Z.exe
  gh release create vX.Y.Z <스크래치>/Flow-vX.Y.Z.exe -R yunytfirst-cell/WebFlow_261108 --target <작업 브랜치> --title "Flow vX.Y.Z" --notes "<CHANGELOG의 그 버전 항목>"
  gh release view vX.Y.Z -R yunytfirst-cell/WebFlow_261108 --json url,assets
  ```
  태그(vX.Y.Z)는 버전 커밋 때 이미 push되어 있어야 한다. 같은 버전 Release가 있으면 `gh release upload vX.Y.Z <파일> --clobber`.
- 기록: v1.3.8 → https://github.com/yunytfirst-cell/WebFlow_261108/releases/tag/v1.3.8 , `Flow-v1.3.8.exe` 17,174,016 bytes (2026-11-24).

## 작업 절차

- 시작 전: 코드 변경이 함께 있으면 `flutter analyze lib test`, `flutter test`가 통과하는지 먼저 확인한다.
- 실행 후: 결과 경로·크기를 보고하고, 실제로 실행해 보지 않았으면 그렇다고 말한다.
- 빌드 후 확인 (2026-11-21부터 매번, PowerShell):
  ```
  (Get-Item dist\Flow.exe).VersionInfo | Select FileVersion, ProductVersion   # pubspec 버전과 같아야 함 (예: 1.2.0+8)
  Start-Process dist\Flow.exe; Get-Process | ? { $_.MainWindowTitle -like 'Flow v*' } | Select Path, MainWindowTitle
  ```
  단일 exe를 실제로 띄워 창 제목 `Flow v<버전>`이 보이면 성공으로 보고한다. 개발용 `build/windows/x64/runner/Release/flow.exe` 창과 함께 떠 있어도 된다.
- 빌드 기록: v1.2.0+8 → `dist\Flow.exe` 16.4MB, 파일 30개 묶음 (2026-11-21).
- 빌드 기록: v1.2.2+10 → `dist\Flow.exe` 16.4MB, 파일 30개, 창 제목 `Flow v1.2.2` 확인 (2026-11-21).
- 빌드 기록: v1.3.8+23 → 새 노란 아이콘, `dist\Flow.exe` (2026-11-24).
- 빌드 기록: v1.3.7+22 → `dist\Flow.exe` 16.4MB, 파일 30개, 창 제목 `Flow v1.3.7` 확인 (2026-11-24). 바탕화면에 사용자가 옮겨 둔 옛 exe(`flow_single_26112103.exe`, v1.2.2)가 함께 떠 있었다 — 건드리지 않고, 새 버전은 `dist\Flow.exe`라고 알려준다.
- 빌드 기록: v1.6.4+34 → `dist\Flow.exe` 16.5MB, 파일 버전 1.6.4+34, 단일 exe 창 제목 `Flow v1.6.4` 확인 (2026-11-25).
- 빌드 기록: v1.7.3+39 → `--skip-build`(run_app 빌드가 마지막 코드 커밋보다 나중), `dist\Flow.exe` 16.5MB, 파일 버전 1.7.3+39, 창 제목 `Flow v1.7.3` 확인 (2026-11-26).
- 빠른 방법(2026-11-25): `build/windows/x64/runner/Release/flow.exe` 시각이 마지막 앱 코드 커밋(`git log -1 --format=%cd -- lib pubspec.yaml windows assets`)보다 나중이면 `--skip-build`로 묶기만 한다(작업 끝마다 run_app.py가 이미 릴리스 빌드함). 아니면 그냥 `python tools/build_exe.py`.
- 사용자는 "실행파일들것"처럼 줄여·오타로 요청하기도 한다 → "실행파일 만들 것"으로 보고 묻지 않고 이 절차를 실행한다.
- 버전 확인은 `$v=(Get-Item dist\Flow.exe).VersionInfo; "$($v.FileVersion)"`처럼 문자열로 찍는다(`Select` 표 출력은 줄이 잘려 `1`만 보일 때가 있었음).
- 빌드 방법이 바뀌면 이 문서와 스크립트를 함께 고친다.
