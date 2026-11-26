@echo off
rem Build Flow single exe (double-click). Comments must stay ASCII: cmd reads .bat as CP949.
cd /d "%~dp0.."
python tools\build_exe.py %*
pause
