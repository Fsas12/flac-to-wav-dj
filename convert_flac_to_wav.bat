@echo off
mkdir wav 2>nul
for %%a in (*) do (
    if /I "%%~xa"==".flac" ffmpeg -i "%%a" "wav\%%~na.wav"
    if /I "%%~xa"==".aif" ffmpeg -i "%%a" "wav\%%~na.wav"
    if /I "%%~xa"==".aiff" ffmpeg -i "%%a" "wav\%%~na.wav"
)
pause
