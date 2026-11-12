@echo off
rem Flow 실행파일 만들기 (더블클릭 또는 터미널에서 실행)
cd /d "%~dp0.."
python tools\build_exe.py %*
pause
