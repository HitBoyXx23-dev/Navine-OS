@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "VBOX=%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe"
if not exist "%VBOX%" set "VBOX=%ProgramFiles(x86)%\Oracle\VirtualBox\VBoxManage.exe"

if not exist "%VBOX%" (
    echo VirtualBox not installed - https://www.virtualbox.org/
    exit /b 1
)

if not exist "build\navine.img" (
    echo Missing build\navine.img - run build.bat first
    exit /b 1
)

"%VBOX%" list vms | findstr /C:"\"Navine OS\"" >nul 2>&1
if errorlevel 1 (
    echo VM not registered - creating...
    powershell -NoProfile -ExecutionPolicy Bypass -File tools\vbox-create.ps1 -BuildDir build
    if errorlevel 1 exit /b 1
) else (
    "%VBOX%" showvminfo "Navine OS" --machinereadable 2>nul | findstr /C:"navine.vdi" >nul 2>&1
    if errorlevel 1 (
        echo VM disk missing - recreating...
        powershell -NoProfile -ExecutionPolicy Bypass -File tools\vbox-create.ps1 -BuildDir build
        if errorlevel 1 exit /b 1
    )
)

powershell -NoProfile -ExecutionPolicy Bypass -File tools\vbox-repair.ps1 >nul 2>&1
if errorlevel 2 (
    echo.
    echo VirtualBox drivers are broken ^(VMMR0.r0^). Reinstall VirtualBox:
    echo   powershell -File tools\vbox-repair.ps1
    echo.
    exit /b 1
)

echo Starting Navine OS in VirtualBox...
"%VBOX%" startvm "Navine OS"
exit /b %ERRORLEVEL%
