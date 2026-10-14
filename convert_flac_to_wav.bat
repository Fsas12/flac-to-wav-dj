@echo off
mkdir wav 2>nul
for %%a in (*.flac) do ffmpeg -i "%%a" "wav\%%~na.wav"
pause