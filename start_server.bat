@echo off
title ProScheduler — Prolog Server
cd /d "%~dp0"
echo.
echo [ProScheduler] Stopping previous SWI-Prolog instances (if any)...
taskkill /IM swipl.exe /F >nul 2>&1
taskkill /IM swipl-win.exe /F >nul 2>&1

echo [ProScheduler] Waiting for port 8080 to be released...
timeout /t 1 /nobreak >nul

echo [ProScheduler] Looking for SWI-Prolog...

where swipl >nul 2>&1
if %errorlevel% equ 0 (
    echo [ProScheduler] Found swipl in PATH
    swipl server.pl
) else (
    echo [ProScheduler] swipl not in PATH — trying default install locations...
    if exist "C:\Program Files\swipl\bin\swipl.exe" (
        "C:\Program Files\swipl\bin\swipl.exe" server.pl
    ) else if exist "C:\Program Files (x86)\swipl\bin\swipl.exe" (
        "C:\Program Files (x86)\swipl\bin\swipl.exe" server.pl
    ) else (
        echo.
        echo [ERROR] SWI-Prolog not found.
        echo Download from: https://www.swi-prolog.org/Download.html
        echo Then add swipl to your PATH or install to the default location.
        pause
        exit /b 1
    )
)
pause
