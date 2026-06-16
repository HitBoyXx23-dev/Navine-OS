; Navine OS - File Launcher (runs any registered file type)

[BITS 64]

%include "constants.inc"

%define FT_UNKNOWN     0
%define FT_TEXT        1
%define FT_BINARY      2
%define FT_WAD         3
%define FT_DOOM        4
%define FT_THEME       5
%define FT_PLUGIN      6
%define FT_MEDIA       7
%define FT_IMAGE       8
%define FT_ARCHIVE     9
%define FT_PE          10
%define FT_SCRIPT      11
%define FT_NAVAPP      12
%define FT_DISK        13
%define FT_JSON        14
%define FT_HTML        15

global init_launcher
global filetype_run
global launcher_last_status

section .bss
launcher_last_status: resb 128

section .text
init_launcher:
    ret

filetype_run:
    push rbx
    push r12
    mov r12, rdi
    call filetype_get_handler
    test rax, rax
    jz .unknown
    mov bl, al
    mov rdi, r12
    cmp bl, FT_TEXT
    je .text
    cmp bl, FT_JSON
    je .text
    cmp bl, FT_HTML
    je .text
    cmp bl, FT_SCRIPT
    je .script
    cmp bl, FT_WAD
    je .wad
    cmp bl, FT_DOOM
    je .doom
    cmp bl, FT_THEME
    je .theme
    cmp bl, FT_PLUGIN
    je .plugin
    cmp bl, FT_MEDIA
    je .media
    cmp bl, FT_IMAGE
    je .image
    cmp bl, FT_ARCHIVE
    je .archive
    cmp bl, FT_PE
    je .pe
    cmp bl, FT_NAVAPP
    je .navapp
    cmp bl, FT_DISK
    je .disk
    cmp bl, FT_BINARY
    je .binary
    jmp .unknown

.text:
    mov rdi, r12
    call textviewer_open
    jmp .done
.script:
    mov rdi, r12
    call textviewer_open
    lea rdi, [msg_script_run]
    call terminal_write
    jmp .done
.wad:
.doom:
    call doom_launch
    jmp .done
.theme:
    mov rdi, r12
    call theme_load
    call theme_apply
    lea rdi, [msg_theme_ok]
    call terminal_write
    jmp .done
.plugin:
    mov rdi, r12
    call plugin_load
    lea rdi, [msg_plugin_ok]
    call terminal_write
    jmp .done
.media:
    lea rdi, [msg_media_open]
    call terminal_write
    jmp .done
.image:
    lea rdi, [msg_image_open]
    call terminal_write
    jmp .done
.archive:
    lea rdi, [msg_archive_open]
    call terminal_write
    jmp .done
.pe:
    mov rdi, r12
    call pe_load
    test rax, rax
    jnz .pe_ok
    lea rdi, [msg_pe_fail]
    call terminal_write
    jmp .done
.pe_ok:
    lea rdi, [msg_pe_ok]
    call terminal_write
    jmp .done
.navapp:
    lea rdi, [msg_navapp_open]
    call terminal_write
    jmp .done
.disk:
    lea rdi, [msg_disk_open]
    call terminal_write
    jmp .done
.binary:
    lea rdi, [msg_binary_open]
    call terminal_write
    jmp .done
.unknown:
    lea rdi, [msg_unknown_type]
    call terminal_write
.done:
    pop r12
    pop rbx
    ret

section .rodata
msg_unknown_type: db 10, "Unknown file type", 10, 0
msg_script_run:   db "Script executed", 10, 0
msg_theme_ok:     db "Theme applied", 10, 0
msg_plugin_ok:    db "Plugin loaded", 10, 0
msg_media_open:   db "Opening in Navine Audio...", 10, 0
msg_image_open:   db "Opening in Photos...", 10, 0
msg_archive_open: db "Opening archive...", 10, 0
msg_pe_ok:        db "Executable loaded", 10, 0
msg_pe_fail:      db "Executable load unavailable", 10, 0
msg_navapp_open:  db "Launching Navine app...", 10, 0
msg_disk_open:    db "Mounting disk image...", 10, 0
msg_binary_open:  db "Binary loader invoked", 10, 0
