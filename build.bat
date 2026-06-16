@echo off
setlocal EnableExtensions
cd /d "%~dp0"

where nasm >nul 2>&1 || (
    echo ERROR: NASM required - https://www.nasm.us/
    exit /b 1
)

if not exist build mkdir build

echo [0/9] Clean intermediate files...
powershell -NoProfile -ExecutionPolicy Bypass -File tools\clean.ps1 -BuildDir build

echo [1/9] Stage 1 bootloader...
nasm -f bin -I include\ -o build\stage1.bin boot\stage1.asm || exit /b 1

echo [2/9] Stage 2 bootloader...
nasm -f bin -I include\ -o build\stage2.bin boot\stage2.asm || exit /b 1

echo [3/9] Wallpaper...
python tools\convert_wallpaper.py build || (
    echo ERROR: pip install pillow
    exit /b 1
)

echo [4/9] Kernel...
nasm -f bin -I include\ -I kernel\ -w- -o build\kernel.bin kernel\link.asm || exit /b 1

echo [5/9] DOOM WAD...
powershell -NoProfile -ExecutionPolicy Bypass -File tools\fetch-doom-wad.ps1 -BuildDir build
powershell -NoProfile -ExecutionPolicy Bypass -File tools\prepare-doom-wad.ps1 -BuildDir build

echo [6/10] DOOM binary...
call apps\doom\build-doom.bat || exit /b 1

echo [7/10] C++ native app...
call apps\system\build-system.bat || exit /b 1

echo [8/10] Disk image...
powershell -NoProfile -ExecutionPolicy Bypass -File tools\mkdisk.ps1 -BuildDir build || exit /b 1

echo [9/10] Bootable ISO...
powershell -NoProfile -ExecutionPolicy Bypass -File tools\mkiso.ps1 -BuildDir build || exit /b 1

echo [10/10] VirtualBox VM...
powershell -NoProfile -ExecutionPolicy Bypass -File tools\vbox-create.ps1 -BuildDir build
set VBOX_ERR=%ERRORLEVEL%

echo.
echo Build complete.
echo   build\navine.img      - VirtualBox hard disk (raw)
echo   build\navine.img      - Raw disk (USB)
echo   build\Navine OS.iso  - Bootable ISO
echo.
echo VirtualBox: run-vbox.bat
echo.

if %VBOX_ERR%==2 (
    echo VirtualBox drivers are broken. Run:
    echo   powershell -File tools\vbox-repair.ps1
    echo Then uninstall/reinstall VirtualBox and run build.bat again.
)

exit /b 0
