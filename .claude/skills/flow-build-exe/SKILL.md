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

## 작업 절차

- 시작 전: 코드 변경이 함께 있으면 `flutter analyze lib test`, `flutter test`가 통과하는지 먼저 확인한다.
- 실행 후: 결과 경로·크기를 보고하고, 실제로 실행해 보지 않았으면 그렇다고 말한다.
- 빌드 후 확인 (2026-11-21부터 매번, PowerShell):
  ```
  (Get-Item dist\Flow.exe).VersionInfo | Select FileVersion, ProductVersion   # pubspec 버전과 같아야 함 (예: 1.2.0+8)
  Start-Process dist\Flow.exe; Get-Process | ? { $_.MainWindowTitle -like 'Flow v*' } | Select Path, MainWindowTitle
  ```
  단일 exe를 실제로 띄워 창 제목 `Flow v<버전>`이 보이면 성공으로 보고한다. 개발용 `build\...low.exe` 창과 함께 떠 있어도 된다.
- 빌드 기록: v1.2.0+8 → `dist\Flow.exe` 16.4MB, 파일 30개 묶음 (2026-11-21).
- 빌드 기록: v1.2.2+10 → `dist\Flow.exe` 16.4MB, 파일 30개, 창 제목 `Flow v1.2.2` 확인 (2026-11-21).
- 빌드 기록: v1.3.7+22 → `dist\Flow.exe` 16.4MB, 파일 30개, 창 제목 `Flow v1.3.7` 확인 (2026-11-24). 바탕화면에 사용자가 옮겨 둔 옛 exe(`flow_single_26112103.exe`, v1.2.2)가 함께 떠 있었다 — 건드리지 않고, 새 버전은 `dist\Flow.exe`라고 알려준다.
- 사용자는 "실행파일들것"처럼 줄여·오타로 요청하기도 한다 → "실행파일 만들 것"으로 보고 묻지 않고 이 절차를 실행한다.
- 버전 확인은 `$v=(Get-Item dist\Flow.exe).VersionInfo; "$($v.FileVersion)"`처럼 문자열로 찍는다(`Select` 표 출력은 줄이 잘려 `1`만 보일 때가 있었음).
- 빌드 방법이 바뀌면 이 문서와 스크립트를 함께 고친다.
