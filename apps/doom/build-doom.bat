@echo off
setlocal EnableExtensions
cd /d "%~dp0\..\.."

set "ROOT=%CD%"
set "DG=%ROOT%\third_party\doomgeneric\doomgeneric"
set "OUT=%ROOT%\build\doom"
set "INC=-nostdinc -I"%ROOT%\apps\doom\navine_stdinc" -I"%DG%" -I"%ROOT%\apps\doom" -include navine_compat.h"
set "CFLAGS=-ffreestanding -O2 -DNAVINE_OS -mno-red-zone -fno-pic -fno-pie -fno-asynchronous-unwind-tables -fno-unwind-tables -Wall -Wno-unused -Wno-implicit-function-declaration -Wno-builtin-declaration-mismatch -Wno-pointer-to-int-cast -Wno-dangling-pointer -U_WIN32"

where gcc >nul 2>&1 || (echo ERROR: gcc required & exit /b 1)
where nasm >nul 2>&1 || (echo ERROR: nasm required & exit /b 1)
where ld >nul 2>&1 || (echo ERROR: ld required & exit /b 1)
where objcopy >nul 2>&1 || (echo ERROR: objcopy required & exit /b 1)

if not exist "%OUT%" mkdir "%OUT%"
if not exist "%ROOT%\build" mkdir "%ROOT%\build"

echo Building DOOM (doomgeneric)...

nasm -f win64 -o "%ROOT%\build\doom_crt0.o" "%ROOT%\apps\doom\navine_crt0.asm" || exit /b 1

for %%f in (
  am_map doomdef doomgeneric doomstat dstrings dummy d_event d_items
  d_iwad d_loop d_main d_mode d_net f_finale f_wipe gusconf g_game
  hu_lib hu_stuff icon info i_cdmus i_endoom i_input i_joystick
  i_scale i_sound i_timer i_video memio m_argv m_bbox
  m_cheat m_config m_controls m_fixed m_menu m_misc m_random
  p_ceilng p_doors p_enemy p_floor p_inter p_lights p_map p_maputl
  p_mobj p_plats p_pspr p_saveg p_setup p_sight p_spec p_switch
  p_telept p_tick p_user r_bsp r_data r_draw r_main r_plane r_segs
  r_sky r_things sha1 sounds statdump st_lib st_stuff s_sound
  tables v_video wi_stuff w_checksum w_file w_main w_wad z_zone
) do (
  gcc -c %CFLAGS% %INC% -o "%OUT%\%%f.o" "%DG%\%%f.c" || exit /b 1
)

gcc -c %CFLAGS% %INC% -o "%OUT%\i_system_navine.o" "%ROOT%\apps\doom\i_system_navine.c" || exit /b 1
gcc -c %CFLAGS% %INC% -o "%OUT%\doomgeneric_navine.o" "%ROOT%\apps\doom\doomgeneric_navine.c" || exit /b 1
gcc -c %CFLAGS% %INC% -o "%OUT%\navine_libc.o" "%ROOT%\apps\doom\navine_libc.c" || exit /b 1
gcc -c %CFLAGS% %INC% -o "%OUT%\w_file_navine.o" "%ROOT%\apps\doom\w_file_navine.c" || exit /b 1

ld -m i386pep -nostdlib -T "%ROOT%\apps\doom\link.pe.ld" -o "%ROOT%\build\doom.exe" "%ROOT%\build\doom_crt0.o" "%OUT%\*.o" 2>nul || exit /b 1
objcopy -O binary "%ROOT%\build\doom.exe" "%ROOT%\build\doom.bin" || exit /b 1

for %%A in ("%ROOT%\build\doom.bin") do echo Created build\doom.bin (%%~zA bytes)
exit /b 0
