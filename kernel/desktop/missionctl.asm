; Navine OS - Mission Control (workspace overview)

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern fb_fill_rect
extern font_draw_string
extern fb_width
extern fb_height
extern windows
extern window_count
%endif

global init_mission_control
global mission_control_toggle
global mission_control_render
global mission_control_is_open

section .bss
mission_open: resb 1

section .text
init_mission_control:
    mov byte [mission_open], 0
    ret

mission_control_toggle:
    xor byte [mission_open], 1
    ret

mission_control_is_open:
    movzx rax, byte [mission_open]
    ret

mission_control_render:
    cmp byte [mission_open], 0
    je .done
    mov edi, 0
    mov esi, 0
    mov edx, [fb_width]
    mov ecx, [fb_height]
    mov r8d, 0xAA05080C
    call fb_fill_rect
    mov eax, [fb_width]
    sub eax, 520
    shr eax, 1
    mov r12d, eax
    mov eax, [fb_height]
    sub eax, 360
    shr eax, 1
    mov r13d, eax
    mov edi, r12d
    mov esi, r13d
    mov edx, 520
    mov ecx, 360
    mov r8d, 0xF0121820
    call fb_fill_rect
    mov edi, r12d
    add edi, 24
    mov esi, r13d
    add esi, 24
    lea rdx, [title_mc]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, r12d
    add edi, 24
    mov esi, r13d
    add esi, 64
    lea rdx, [hint_mc]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov edi, r12d
    add edi, 40
    mov esi, r13d
    add esi, 110
    mov edx, 220
    mov ecx, 140
    mov r8d, 0xFF273241
    call fb_fill_rect
    mov edi, r12d
    add edi, 52
    mov esi, r13d
    add esi, 124
    lea rdx, [win_terminal]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, r12d
    add edi, 280
    mov esi, r13d
    add esi, 110
    mov edx, 200
    mov ecx, 140
    mov r8d, 0xFF273241
    call fb_fill_rect
    mov edi, r12d
    add edi, 292
    mov esi, r13d
    add esi, 124
    lea rdx, [win_apps]
    mov ecx, COLOR_WHITE
    call font_draw_string
.done:
    ret

section .rodata
title_mc:    db "Mission Control", 0
hint_mc:     db "Press M to close  Space 1-4 switch workspace", 0
win_terminal: db "Console", 0
win_apps:    db "Apps + Vault", 0
