@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "VBOX=%ProgramFiles%\Oracle\VirtualBox\VBoxManage.exe"
if not exist "%VBOX%" set "VBOX=%ProgramFiles(x86)%\Oracle\VirtualBox\VBoxManage.exe"
if not exist "%VBOX%" (
    echo VirtualBox not installed.
    exit /b 1
)

if not exist "build\Navine OS.iso" (
    echo Missing build\Navine OS.iso - run build.bat first
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File tools\vbox-create.ps1 -BuildDir build
if errorlevel 1 exit /b 1

set "ISO=%CD%\build\Navine OS.iso"
"%VBOX%" storageattach "Navine OS" --storagectl "IDE" --port 1 --device 0 --type dvddrive --medium "%ISO%"
"%VBOX%" modifyvm "Navine OS" --boot1 dvd --boot2 disk
echo.
echo VM configured for ISO boot. Start with run-vbox.bat
echo Boot debug log: build\serial.log  (after VM runs once)
echo VBox crash log: %%USERPROFILE%%\VirtualBox VMs\Navine OS\Logs\VBox.log
exit /b 0
