@echo off
setlocal EnableExtensions
cd /d "%~dp0\..\.."

set "ROOT=%CD%"
set "OUT=%ROOT%\build\system"
set "CXXFLAGS=-ffreestanding -O2 -mno-red-zone -fno-pic -fno-pie -fno-exceptions -fno-rtti -fno-asynchronous-unwind-tables -fno-unwind-tables -Wall -Wextra"

where g++ >nul 2>&1 || (echo ERROR: g++ required & exit /b 1)
where ld >nul 2>&1 || (echo ERROR: ld required & exit /b 1)
where objcopy >nul 2>&1 || (echo ERROR: objcopy required & exit /b 1)

if not exist "%OUT%" mkdir "%OUT%"
if not exist "%ROOT%\build" mkdir "%ROOT%\build"

echo Building C++ System app...
g++ -c %CXXFLAGS% -o "%OUT%\system.o" "%ROOT%\apps\system\system.cpp" || exit /b 1
ld -m i386pep -nostdlib -T "%ROOT%\apps\system\link.pe.ld" -o "%ROOT%\build\system.exe" "%OUT%\system.o" 2>nul || exit /b 1
objcopy -O binary "%ROOT%\build\system.exe" "%ROOT%\build\system.bin" || exit /b 1

for %%A in ("%ROOT%\build\system.bin") do echo Created build\system.bin (%%~zA bytes)
exit /b 0
