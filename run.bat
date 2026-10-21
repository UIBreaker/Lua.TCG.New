@echo off
cd /d "%~dp0"
title Poker Roguelike Launcher
echo Dang khoi dong Poker Roguelike Demo voi LOVE 11.5...

REM Kiem tra love trong PATH
where love.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    start "" love .
    exit
)

REM Kiem tra thu muc cha
if exist "..\love-11.5-win64\love.exe" (
    start "" "..\love-11.5-win64\love.exe" .
    exit
)

REM Kiem tra thu muc Program Files
if exist "C:\Program Files\LOVE\love.exe" (
    start "" "C:\Program Files\LOVE\love.exe" .
    exit
)

if exist "C:\Program Files (x86)\LOVE\love.exe" (
    start "" "C:\Program Files (x86)\LOVE\love.exe" .
    exit
)

echo [LOI] Khong tim thay love.exe! Vui long cai dat Love2D hoac dat folder love-11.5-win64 vao thu muc cha.
pause
exit /b 1
