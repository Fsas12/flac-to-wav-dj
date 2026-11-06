@echo off
setlocal DisableDelayedExpansion
cd /d "%~dp0" || exit /b 1
set "FFMPEG="
if exist "%~dp0ffmpeg.exe" set "FFMPEG=%~dp0ffmpeg.exe"
if not defined FFMPEG for /f "delims=" %%f in ('where ffmpeg.exe 2^>nul') do if not defined FFMPEG set "FFMPEG=%%f"
if not defined FFMPEG if exist "%LOCALAPPDATA%\FLAC-to-WAV-DJ\ffmpeg\ffmpeg.exe" set "FFMPEG=%LOCALAPPDATA%\FLAC-to-WAV-DJ\ffmpeg\ffmpeg.exe"
if not defined FFMPEG (
    powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File "%~dp0Install-FFmpeg.ps1"
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
mkdir wav 2>nul
for %%a in (*) do (
    if /I "%%~xa"==".flac" "%FFMPEG%" -i "%%a" "wav\%%~na.wav"
    if /I "%%~xa"==".aif" "%FFMPEG%" -i "%%a" "wav\%%~na.wav"
    if /I "%%~xa"==".aiff" "%FFMPEG%" -i "%%a" "wav\%%~na.wav"
)
pause
