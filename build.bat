@echo off
setlocal EnableExtensions
cd /d "%~dp0"

where nasm >nul 2>&1 || (
    echo ERROR: NASM required - https://www.nasm.us/
    exit /b 1
)

if not exist build mkdir build

echo [0/11] Clean intermediate files...
powershell -NoProfile -ExecutionPolicy Bypass -File tools\clean.ps1 -BuildDir build

echo [1/11] Stage 1 bootloader...
nasm -f bin -I include\ -o build\stage1.bin boot\stage1.asm || exit /b 1

echo [2/11] Stage 2 bootloader...
nasm -f bin -I include\ -o build\stage2.bin boot\stage2.asm || exit /b 1

echo [3/11] Wallpaper...
python tools\convert_wallpaper.py build || (
    echo ERROR: pip install pillow
    exit /b 1
)

echo [4/11] Desktop kernel...
nasm -f bin -I include\ -I kernel\ -w- -o build\kernel.bin kernel\link.asm || exit /b 1

echo [5/11] CLI kernel...
nasm -f bin -I include\ -I kernel\ -w- -o build\kernel-cli.bin kernel\link-cli.asm || exit /b 1

echo [6/11] DOOM WAD...
powershell -NoProfile -ExecutionPolicy Bypass -File tools\fetch-doom-wad.ps1 -BuildDir build
powershell -NoProfile -ExecutionPolicy Bypass -File tools\prepare-doom-wad.ps1 -BuildDir build

echo [7/11] DOOM binary...
call apps\doom\build-doom.bat || exit /b 1

echo [8/11] C++ native app...
call apps\system\build-system.bat || exit /b 1

echo [9/11] Desktop disk image...
powershell -NoProfile -ExecutionPolicy Bypass -File tools\mkdisk.ps1 -BuildDir build -KernelName kernel.bin -OutputImg navine-desktop.img || exit /b 1

echo [10/11] CLI disk image...
powershell -NoProfile -ExecutionPolicy Bypass -File tools\mkdisk.ps1 -BuildDir build -KernelName kernel-cli.bin -OutputImg navine-cli.img || exit /b 1

echo [11/11] Bootable ISOs...
powershell -NoProfile -ExecutionPolicy Bypass -File tools\mkiso.ps1 -BuildDir build -DiskImage navine-desktop.img -IsoName "Navine OS Desktop.iso" || exit /b 1
powershell -NoProfile -ExecutionPolicy Bypass -File tools\mkiso.ps1 -BuildDir build -DiskImage navine-cli.img -IsoName "Navine OS CLI.iso" || exit /b 1

copy /Y build\navine-desktop.img build\navine.img >nul

echo.
echo Build complete.
echo   build\Navine OS Desktop.iso
echo   build\Navine OS CLI.iso
echo   build\navine-desktop.img
echo   build\navine-cli.img
echo.

exit /b 0
