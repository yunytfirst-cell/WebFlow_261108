"""Flow 앱을 빌드해서 화면에 띄운다 (윈도우 데스크톱).

사용법 (프로젝트 루트에서):
    python tools/run_app.py              # 릴리스 빌드(약 25초) 후 실행
    python tools/run_app.py --skip-build # 이미 빌드된 앱을 바로 실행

이미 떠 있는 Flow 창은 닫고 새로 빌드한 앱을 띄운다 (빌드 결과 exe가 잠겨 빌드가 실패하는 것을 막기 위해).
"""

import argparse
import os
import subprocess
import sys
import time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXE = os.path.join(ROOT, 'build', 'windows', 'x64', 'runner', 'Release', 'flow.exe')


def running_pids():
    """build 폴더의 flow.exe로 실행 중인 프로세스 ID들 (dist의 Flow.exe는 건드리지 않음)."""
    ps = (
        "Get-Process flow -ErrorAction SilentlyContinue | "
        f"Where-Object {{ $_.Path -eq '{EXE}' }} | ForEach-Object {{ $_.Id }}"
    )
    out = subprocess.run(['powershell', '-NoProfile', '-Command', ps], capture_output=True, text=True).stdout
    return [line.strip() for line in out.splitlines() if line.strip().isdigit()]


def close_running():
    pids = running_pids()
    for pid in pids:
        subprocess.run(['taskkill', '/PID', pid, '/F'], capture_output=True)
    if pids:
        print(f'> 실행 중이던 Flow 종료 ({", ".join(pids)})')
        time.sleep(1)


def main():
    parser = argparse.ArgumentParser(description='Flow 앱 실행')
    parser.add_argument('--skip-build', action='store_true', help='빌드를 건너뛰고 바로 실행')
    args = parser.parse_args()

    close_running()
    if not args.skip_build:
        print('> flutter build windows --release')
        subprocess.run('flutter build windows --release', cwd=ROOT, shell=True, check=True)
    if not os.path.isfile(EXE):
        sys.exit(f'실행 파일이 없습니다: {EXE}')

    flags = subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP
    subprocess.Popen([EXE], cwd=os.path.dirname(EXE), creationflags=flags,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    for _ in range(20):
        time.sleep(0.5)
        if running_pids():
            print(f'\nFlow 앱을 화면에 띄웠습니다: {EXE}')
            return
    sys.exit('앱 프로세스가 확인되지 않습니다 (바로 종료되었을 수 있음)')


if __name__ == '__main__':
    main()
