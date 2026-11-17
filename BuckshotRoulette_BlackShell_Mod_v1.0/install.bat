@echo off
setlocal

echo ==================================================
echo  Buckshot Roulette - Black Shell Mod  (install)
echo ==================================================
echo.

set "ARG=%~1"

tasklist /FI "IMAGENAME eq Buckshot Roulette.exe" 2>nul | find /I "Buckshot Roulette.exe" >nul
if not errorlevel 1 (
    echo [WARN] The game is running. Close it completely first, then run this again.
    echo.
    pause
    exit /b 1
)

if "%ARG%"=="" (
    echo Searching for the game automatically...
) else (
    echo Game path from argument: %ARG%
)
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0patch.ps1" -Action patch -ExePath "%ARG%" -Manifest "%~dp0install_backup.json"
if errorlevel 1 (
    echo.
    echo [ERROR] Install failed - see the message above.
    echo.
    echo If the game was not found automatically, drag the folder that contains
    echo "Buckshot Roulette.exe" onto install.bat, or run:
    echo    install.bat "D:\Steam\steamapps\common\Buckshot Roulette\Buckshot Roulette_windows"
    echo.
    echo If it says "access denied", right-click install.bat - Run as administrator.
    echo.
    pause
    exit /b 1
)

echo.
echo [OK] Black Shell Mod installed. Start the game to play.
echo      Uninstall: run uninstall.bat  (or Steam - Verify integrity of game files)
echo.
pause
