"""Flow 웹 미리보기: 웹으로 빌드하고 로컬 서버를 띄운 뒤 브라우저로 연다.

사용법 (프로젝트 루트에서):
    python tools/preview_web.py              # 빌드 + 서버 + 브라우저 열기
    python tools/preview_web.py --skip-build # 이미 빌드된 build/web으로 열기만

주소: http://127.0.0.1:8765/
서버는 백그라운드로 계속 떠 있다. 이미 떠 있으면 새로 띄우지 않고 브라우저만 연다.
"""

import argparse
import os
import socket
import subprocess
import sys
import time
import urllib.request
import webbrowser

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB_DIR = os.path.join(ROOT, 'build', 'web')
HOST = '127.0.0.1'
PORT = 8765
URL = f'http://{HOST}:{PORT}/'


def server_running():
    with socket.socket() as s:
        s.settimeout(0.5)
        return s.connect_ex((HOST, PORT)) == 0


def start_server():
    flags = 0
    if os.name == 'nt':
        flags = subprocess.DETACHED_PROCESS | subprocess.CREATE_NEW_PROCESS_GROUP
    subprocess.Popen(
        [sys.executable, '-m', 'http.server', str(PORT), '--bind', HOST],
        cwd=WEB_DIR,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        creationflags=flags,
    )
    for _ in range(20):
        if server_running():
            return
        time.sleep(0.25)
    sys.exit('웹 서버를 띄우지 못했습니다')


def main():
    parser = argparse.ArgumentParser(description='Flow 웹 미리보기')
    parser.add_argument('--skip-build', action='store_true', help='flutter 웹 빌드를 건너뜀')
    parser.add_argument('--no-open', action='store_true', help='브라우저를 열지 않음')
    args = parser.parse_args()

    if not args.skip_build:
        print('> flutter build web --release')
        subprocess.run('flutter build web --release', cwd=ROOT, shell=True, check=True)
    if not os.path.isfile(os.path.join(WEB_DIR, 'index.html')):
        sys.exit(f'웹 빌드 결과가 없습니다: {WEB_DIR}')

    if server_running():
        print('> 웹 서버가 이미 실행 중 (새 빌드는 새로고침하면 보임)')
    else:
        start_server()
        print('> 웹 서버 시작')

    status = urllib.request.urlopen(URL, timeout=5).status
    print(f'> {URL} 응답 {status}')
    if not args.no_open:
        webbrowser.open(URL)
    print(f'\n웹에서 확인: {URL}')


if __name__ == '__main__':
    main()
