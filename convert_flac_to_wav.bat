@echo off
setlocal DisableDelayedExpansion
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Convert-FlacToWav.ps1" %*
set "result=%errorlevel%"
pause
exit /b %result%
