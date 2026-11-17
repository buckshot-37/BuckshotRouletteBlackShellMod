@echo off
setlocal

echo ==================================================
echo  Buckshot Roulette - Black Shell Mod  (uninstall)
echo ==================================================
echo.

set "ARG=%~1"

if not exist "%~dp0install_backup.json" (
    echo [INFO] install_backup.json was not found next to this script.
    echo        Use Steam - "Verify integrity of game files" to restore the game.
    echo.
    pause
    exit /b 1
)

tasklist /FI "IMAGENAME eq Buckshot Roulette.exe" 2>nul | find /I "Buckshot Roulette.exe" >nul
if not errorlevel 1 (
    echo [WARN] The game is running. Close it completely first, then run this again.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch.ps1" -Action uninstall -ExePath "%ARG%" -Manifest "%~dp0install_backup.json"
if errorlevel 1 (
    echo.
    echo [ERROR] Uninstall failed - see the message above.
    echo         Use Steam - "Verify integrity of game files" to restore the game.
    echo.
    pause
    exit /b 1
)

echo.
echo [OK] Mod removed, original scripts restored.
echo.
pause
