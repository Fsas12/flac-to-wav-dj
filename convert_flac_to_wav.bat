@echo off
setlocal DisableDelayedExpansion
set "WAV_POWERSHELL=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
cd /d "%~dp0" || exit /b 1
set "FFMPEG="
if exist "%~dp0ffmpeg.exe" set "FFMPEG=%~dp0ffmpeg.exe"
if not defined FFMPEG for /f "delims=" %%f in ('where ffmpeg.exe 2^>nul') do if not defined FFMPEG set "FFMPEG=%%f"
if not defined FFMPEG if exist "%LOCALAPPDATA%\FLAC-to-WAV-DJ\ffmpeg\ffmpeg.exe" set "FFMPEG=%LOCALAPPDATA%\FLAC-to-WAV-DJ\ffmpeg\ffmpeg.exe"
if not defined FFMPEG (
    "%WAV_POWERSHELL%" -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Install-FFmpeg.ps1"
    if errorlevel 1 (
        echo Setup was cancelled or could not finish. No audio was converted.
        pause
        exit /b 1
    )
    if not exist "%LOCALAPPDATA%\FLAC-to-WAV-DJ\ffmpeg\ffmpeg.exe" (
        echo FFmpeg setup did not create an executable.
        pause
        exit /b 1
    )
    set "FFMPEG=%LOCALAPPDATA%\FLAC-to-WAV-DJ\ffmpeg\ffmpeg.exe"
)
if not exist "%~dp0Convert-AudioTree.ps1" (
    echo Keep Convert-AudioTree.ps1 beside this launcher.
    pause
    exit /b 2
)
set "INPUT=%~dp0."
if not "%~1"=="" set "INPUT=%~f1\."
"%WAV_POWERSHELL%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Convert-AudioTree.ps1" -InputDirectory "%INPUT%" -FFmpegPath "%FFMPEG%"
set "RESULT=%ERRORLEVEL%"
pause
exit /b %RESULT%
