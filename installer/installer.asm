; Navine OS - Graphical Installer

[BITS 64]

%include "constants.inc"

extern fb_fill_rect
extern font_draw_string

global installer_main

section .rodata
inst_title:   db "Navine OS Installer", 0
inst_mode:    db "Select installation mode:", 0
mode_mac:     db "1. macOS Style", 0
mode_linux:   db "2. Linux Style", 0
mode_win:     db "3. Windows Style", 0
mode_hybrid:  db "4. Hybrid Mode", 0

section .text
installer_main:
    mov edi, 0
    mov esi, 0
    mov edx, 1024
    mov ecx, 768
    mov r8d, COLOR_NAVINE_GRAY
    call fb_fill_rect
    mov edi, 300
    mov esi, 200
    lea rdx, [inst_title]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov esi, 260
    lea rdx, [inst_mode]
    call font_draw_string
    mov esi, 300
    lea rdx, [mode_mac]
    call font_draw_string
    mov esi, 330
    lea rdx, [mode_linux]
    call font_draw_string
    mov esi, 360
    lea rdx, [mode_win]
    call font_draw_string
    mov esi, 390
    lea rdx, [mode_hybrid]
    call font_draw_string
    ret
