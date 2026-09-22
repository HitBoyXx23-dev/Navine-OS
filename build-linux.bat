@echo off
setlocal EnableExtensions
cd /d "%~dp0"

where wsl >nul 2>&1 || (
    echo ERROR: WSL required - https://learn.microsoft.com/windows/wsl/install
    exit /b 1
)

set "TARGET=all"
if not "%~1"=="" set "TARGET=%~1"

if not exist build mkdir build

for /f "usebackq delims=" %%I in (`wsl wslpath -a "%CD%"`) do set "WSLROOT=%%I"
if "%WSLROOT%"=="" (
    echo ERROR: could not resolve WSL path for %CD%
    exit /b 1
)

if /I "%TARGET%"=="desktop" goto :desktop
if /I "%TARGET%"=="cli" goto :cli
if /I "%TARGET%"=="all" goto :all
echo Unknown target: %TARGET%
echo Usage: build-linux.bat [desktop^|cli^|all]
exit /b 1

:all
call :desktop
if errorlevel 1 exit /b 1
call :cli
exit /b %ERRORLEVEL%

:desktop
echo Building Navine OS Linux Desktop (Debian XFCE) via WSL...
echo First run may take 20-40 minutes.
wsl -u root -e bash -lc "cd '%WSLROOT%' && bash linux/build-navine-debian.sh navine" || exit /b 1
if not exist "build\Navine OS Linux Desktop.iso" (
    echo ERROR: Desktop ISO missing
    exit /b 1
)
echo   build\Navine OS Linux Desktop.iso
goto :eof

:cli
echo Building Navine OS Linux CLI (Alpine live shell) via WSL...
wsl -e bash -lc "cd '%WSLROOT%' && bash linux/build-navine-linux.sh" || exit /b 1
if not exist "build\Navine OS Linux CLI.iso" (
    echo ERROR: CLI ISO missing
    exit /b 1
)
echo   build\Navine OS Linux CLI.iso
goto :eof
