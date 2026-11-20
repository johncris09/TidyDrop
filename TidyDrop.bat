@echo off
REM Double-click this file to organize the folder it lives in.
REM It runs organize.ps1 located in the same folder.

setlocal
cd /d "%~dp0"

echo ============================================
echo   File Organizer
echo   Folder: %~dp0
echo ============================================
echo.
echo   [1] Preview only (dry run - moves nothing)
echo   [2] Organize now (move files into _Sorted)
echo   [3] Cancel
echo.
set /p choice=Choose 1, 2 or 3:

if "%choice%"=="1" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0organize.ps1" -DryRun
) else if "%choice%"=="2" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0organize.ps1"
) else (
    echo Cancelled.
)

echo.
pause
endlocal
