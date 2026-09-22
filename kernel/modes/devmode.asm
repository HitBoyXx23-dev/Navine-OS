; Navine OS - Developer Mode (tooling profile, package manager hooks)

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern fb_fill_rect
extern font_draw_string
extern fb_width
extern scheduler_set_priority
%endif

global init_devmode
global devmode_enable
global devmode_disable
global devmode_toggle
global devmode_is_active
global devmode_render_overlay
global devmode_apply_profile

section .bss
devmode_active: resb 1

section .text
init_devmode:
    mov byte [devmode_active], 0
    call npkg_init
    ret

devmode_enable:
    mov byte [devmode_active], 1
    call devmode_apply_profile
    ret

devmode_disable:
    mov byte [devmode_active], 0
    ret

devmode_toggle:
    cmp byte [devmode_active], 0
    je devmode_enable
    jmp devmode_disable

devmode_is_active:
    movzx rax, byte [devmode_active]
    ret

devmode_apply_profile:
    call npkg_init
    mov edi, 0
    mov esi, 15
    call scheduler_set_priority
    ret

devmode_render_overlay:
    cmp byte [devmode_active], 0
    je .done
    mov eax, [fb_width]
    sub eax, 280
    mov edi, eax
    mov esi, 8
    mov edx, 168
    mov ecx, 36
    mov r8d, 0xCC101820
    call fb_fill_rect
    mov edi, eax
    add edi, 10
    mov esi, 14
    lea rdx, [label_dev_mode]
    mov ecx, 0xFF7CFF9A
    call font_draw_string
    mov edi, eax
    add edi, 10
    mov esi, 30
    lea rdx, [label_npkg]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
.done:
    ret

section .rodata
label_dev_mode: db "DEV MODE", 0
label_npkg:     db "npkg ready", 0
