"""Flow 윈도우 실행파일 만들기.

사용법 (프로젝트 루트에서):
    python tools/build_exe.py              # 빌드 + 폴더형 + 단일 exe
    python tools/build_exe.py --skip-build # 이미 빌드된 결과로 패키징만

결과:
    dist/Flow/flow.exe  폴더형 (dll, data 폴더와 함께 실행)
    dist/Flow.exe       단일 실행파일 (Enigma Virtual Box로 묶음)

Enigma 설정 파일(dist/flow_build.evb)은 매번 현재 빌드 파일 목록으로 새로 만든다.
예전 .evb처럼 파일 목록이 고정되어 새 파일이 빠지는 일을 막기 위해서다.
"""

import argparse
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RELEASE_DIR = os.path.join(ROOT, 'build', 'windows', 'x64', 'runner', 'Release')
DIST_DIR = os.path.join(ROOT, 'dist')
APP_DIR = os.path.join(DIST_DIR, 'Flow')
EVB_PATH = os.path.join(DIST_DIR, 'flow_build.evb')
OUT_EXE = os.path.join(DIST_DIR, 'Flow.exe')
ENIGMA = r'C:\Program Files (x86)\Enigma Virtual Box\enigmavbconsole.exe'

# 실행에 필요한 VC++ 런타임 (빌드 결과에 없으면 System32에서 복사)
VC_RUNTIME = ['msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll']


def is_packaging_leftover(name):
    """Release 폴더에 섞여 있는 예전 패키징 파일은 배포에서 뺀다."""
    lower = name.lower()
    return lower.endswith('.evb') or lower.startswith('flow_single')


def run_flutter_build():
    print('> flutter build windows --release')
    subprocess.run('flutter build windows --release', cwd=ROOT, shell=True, check=True)


def sync_app_dir():
    """빌드 결과를 dist/Flow로 복사한다. data 폴더는 통째로 새로 만든다."""
    if not os.path.isfile(os.path.join(RELEASE_DIR, 'flow.exe')):
        sys.exit(f'빌드 결과가 없습니다: {RELEASE_DIR}')
    os.makedirs(APP_DIR, exist_ok=True)
    data_dir = os.path.join(APP_DIR, 'data')
    if os.path.isdir(data_dir):
        shutil.rmtree(data_dir)

    for name in os.listdir(RELEASE_DIR):
        if is_packaging_leftover(name):
            continue
        src = os.path.join(RELEASE_DIR, name)
        dst = os.path.join(APP_DIR, name)
        if os.path.isdir(src):
            shutil.copytree(src, dst, dirs_exist_ok=True)
        else:
            shutil.copy2(src, dst)

    system32 = os.path.join(os.environ.get('SystemRoot', r'C:\Windows'), 'System32')
    for dll in VC_RUNTIME:
        dst = os.path.join(APP_DIR, dll)
        src = os.path.join(system32, dll)
        if not os.path.exists(dst) and os.path.exists(src):
            shutil.copy2(src, dst)


EVB_HEADER = """<?xml version="1.0" encoding="windows-1252"?>
<>
  <InputFile>{input}</InputFile>
  <OutputFile>{output}</OutputFile>
  <Files>
    <Enabled>True</Enabled>
    <DeleteExtractedOnExit>False</DeleteExtractedOnExit>
    <CompressFiles>True</CompressFiles>
    <Files>
      <File>
        <Type>3</Type>
        <Name>%DEFAULT FOLDER%</Name>
        <Action>0</Action>
        <OverwriteDateTime>False</OverwriteDateTime>
        <OverwriteAttributes>False</OverwriteAttributes>
        <HideFromDialogs>0</HideFromDialogs>
        <Files>
"""

EVB_FOOTER = """        </Files>
      </File>
    </Files>
  </Files>
  <Registries>
    <Enabled>False</Enabled>
    <Registries>
      <Registry>
        <Type>1</Type>
        <Virtual>True</Virtual>
        <Name>Classes</Name>
        <ValueType>0</ValueType>
        <Value/>
        <Registries/>
      </Registry>
      <Registry>
        <Type>1</Type>
        <Virtual>True</Virtual>
        <Name>User</Name>
        <ValueType>0</ValueType>
        <Value/>
        <Registries/>
      </Registry>
      <Registry>
        <Type>1</Type>
        <Virtual>True</Virtual>
        <Name>Machine</Name>
        <ValueType>0</ValueType>
        <Value/>
        <Registries/>
      </Registry>
      <Registry>
        <Type>1</Type>
        <Virtual>True</Virtual>
        <Name>Users</Name>
        <ValueType>0</ValueType>
        <Value/>
        <Registries/>
      </Registry>
      <Registry>
        <Type>1</Type>
        <Virtual>True</Virtual>
        <Name>Config</Name>
        <ValueType>0</ValueType>
        <Value/>
        <Registries/>
      </Registry>
    </Registries>
  </Registries>
  <Packaging>
    <Enabled>False</Enabled>
  </Packaging>
  <Options>
    <ShareVirtualSystem>True</ShareVirtualSystem>
    <MapExecutableWithTemporaryFile>True</MapExecutableWithTemporaryFile>
    <TemporaryFileMask/>
    <AllowRunningOfVirtualExeFiles>True</AllowRunningOfVirtualExeFiles>
    <ProcessesOfAnyPlatforms>False</ProcessesOfAnyPlatforms>
  </Options>
  <Storage>
    <Files>
      <Enabled>False</Enabled>
      <Folder>%DEFAULT FOLDER%\\</Folder>
      <RandomFileNames>False</RandomFileNames>
      <EncryptContent>False</EncryptContent>
    </Files>
  </Storage>
</>
"""


def file_xml(name, path, indent):
    p = ' ' * indent
    return (
        f'{p}<File>\n{p}  <Type>2</Type>\n{p}  <Name>{name}</Name>\n{p}  <File>{path}</File>\n'
        f'{p}  <ActiveX>False</ActiveX>\n{p}  <ActiveXInstall>False</ActiveXInstall>\n'
        f'{p}  <Action>0</Action>\n{p}  <OverwriteDateTime>False</OverwriteDateTime>\n'
        f'{p}  <OverwriteAttributes>False</OverwriteAttributes>\n'
        f'{p}  <PassCommandLine>False</PassCommandLine>\n{p}  <HideFromDialogs>0</HideFromDialogs>\n'
        f'{p}</File>\n'
    )


def dir_xml(directory, indent, top=False):
    xml = ''
    count = 0
    for name in sorted(os.listdir(directory)):
        full = os.path.join(directory, name)
        if top and (name.lower() == 'flow.exe' or is_packaging_leftover(name)):
            continue
        if os.path.isdir(full):
            p = ' ' * indent
            child_xml, child_count = dir_xml(full, indent + 4)
            count += child_count
            xml += (
                f'{p}<File>\n{p}  <Type>3</Type>\n{p}  <Name>{name}</Name>\n{p}  <Action>0</Action>\n'
                f'{p}  <OverwriteDateTime>False</OverwriteDateTime>\n'
                f'{p}  <OverwriteAttributes>False</OverwriteAttributes>\n'
                f'{p}  <HideFromDialogs>0</HideFromDialogs>\n{p}  <Files>\n'
                f'{child_xml}{p}  </Files>\n{p}</File>\n'
            )
        else:
            xml += file_xml(name, full, indent)
            count += 1
    return xml, count


def write_evb():
    body, count = dir_xml(APP_DIR, 10, top=True)
    content = (
        EVB_HEADER.format(input=os.path.join(APP_DIR, 'flow.exe'), output=OUT_EXE)
        + body
        + EVB_FOOTER
    )
    with open(EVB_PATH, 'wb') as f:
        f.write(b'\xef\xbb\xbf' + content.encode('utf-8'))
    print(f'> Enigma 설정 생성: {EVB_PATH} (파일 {count}개)')


def pack_single_exe():
    if not os.path.isfile(ENIGMA):
        sys.exit(f'Enigma Virtual Box가 없습니다: {ENIGMA}')
    print('> Enigma Virtual Box로 단일 exe 묶는 중...')
    result = subprocess.run([ENIGMA, EVB_PATH], capture_output=True, text=True)
    if result.returncode != 0 or 'successfully saved' not in result.stdout:
        print(result.stdout[-2000:])
        print(result.stderr[-2000:])
        sys.exit('단일 exe 만들기 실패')


def main():
    parser = argparse.ArgumentParser(description='Flow 윈도우 실행파일 만들기')
    parser.add_argument('--skip-build', action='store_true', help='flutter 빌드를 건너뜀')
    args = parser.parse_args()

    if not args.skip_build:
        run_flutter_build()
    sync_app_dir()
    write_evb()
    pack_single_exe()

    size_mb = os.path.getsize(OUT_EXE) / (1024 * 1024)
    print(f'\n완료\n  폴더형: {os.path.join(APP_DIR, "flow.exe")}\n  단일 exe: {OUT_EXE} ({size_mb:.1f} MB)')


if __name__ == '__main__':
    main()
