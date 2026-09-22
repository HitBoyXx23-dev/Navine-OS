; Navine OS - Deferred initialization (after core boot)

[BITS 64]

global kernel_late_init

%ifndef NAVINE_LINK_BUILD
extern init_vfs
extern init_navinefs
extern config_load
extern acpi_init
extern compat_init
extern init_gamemode
extern init_devmode
extern init_mission_control
extern init_wallpaper
extern init_desktop
extern init_wm
extern init_terminal
extern init_filetypes
extern init_launcher
extern init_textviewer
extern init_files
extern init_doom
extern init_cppapp
extern init_simpleapps
extern init_discord
extern browser_init
%endif

section .bss
late_init_done: resb 1

section .text
kernel_late_init:
    cmp byte [late_init_done], 1
    je .done
    call init_vfs
    call init_navinefs
    call config_load
    call acpi_init
    call compat_init
    call init_gamemode
    call init_devmode
    call init_mission_control
    call init_wallpaper
    call init_desktop
    call init_wm
    call init_terminal
    call init_filetypes
    call init_launcher
    call init_textviewer
    call init_files
    call init_doom
    call init_cppapp
    call init_simpleapps
    call init_discord
    call browser_init
    mov byte [late_init_done], 1
.done:
    ret
