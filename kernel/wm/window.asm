; Navine OS - Window Manager

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern fb_fill_rect
extern font_draw_string
extern mouse_x
extern mouse_y
extern mouse_buttons
%endif

global init_wm
global wm_render
global wm_handle_input
global windows

section .bss
windows:        resb 16 * 64
window_count:   resd 1
focused_window: resd 1
dragging:       resb 1
drag_off_x:     resd 1
drag_off_y:     resd 1
mouse_last:     resb 1

section .text
init_wm:
    mov dword [window_count], 1
    mov dword [focused_window], 0
    mov dword [windows], 260
    mov dword [windows + 4], 120
    mov dword [windows + 8], 760
    mov dword [windows + 12], 420
    mov dword [windows + 16], COLOR_WHITE
    mov byte [windows + 20], 1
    mov byte [mouse_last], 0
    ret

wm_render:
    push rbx
    xor ebx, ebx            ; loop counter (callee-saved across calls)
.win:
    mov ecx, [window_count]
    cmp ebx, ecx
    jge .done
    mov eax, ebx
    imul eax, 64            ; window array offset
    cmp byte [windows + rax + 20], 0
    je .next
    push rax
    mov edi, [windows + rax]
    add edi, 8
    mov esi, [windows + rax + 4]
    add esi, 10
    mov edx, [windows + rax + 8]
    mov ecx, [windows + rax + 12]
    mov r8d, 0x66000000
    call fb_fill_rect
    pop rax
    push rax
    mov edi, [windows + rax]
    mov esi, [windows + rax + 4]
    mov edx, [windows + rax + 8]
    mov ecx, [windows + rax + 12]
    mov r8d, 0xEE161A20
    call fb_fill_rect
    pop rax
    push rax
    mov edi, [windows + rax]
    mov esi, [windows + rax + 4]
    mov edx, [windows + rax + 8]
    mov ecx, 34
    mov r8d, 0xF0282C34
    call fb_fill_rect
    pop rax
    push rax
    mov edi, [windows + rax]
    add edi, 14
    mov esi, [windows + rax + 4]
    add esi, 13
    mov edx, 10
    mov ecx, 10
    mov r8d, 0xFFFF5F57
    call fb_fill_rect
    pop rax
    push rax
    mov edi, [windows + rax]
    add edi, 32
    mov esi, [windows + rax + 4]
    add esi, 13
    mov edx, 10
    mov ecx, 10
    mov r8d, 0xFFFFBD2E
    call fb_fill_rect
    pop rax
    push rax
    mov edi, [windows + rax]
    add edi, 50
    mov esi, [windows + rax + 4]
    add esi, 13
    mov edx, 10
    mov ecx, 10
    mov r8d, 0xFF28C840
    call fb_fill_rect
    pop rax
    mov edi, [windows + rax]
    add edi, 86
    mov esi, [windows + rax + 4]
    add esi, 12
    lea rdx, [title_terminal]
    mov ecx, COLOR_WHITE
    call font_draw_string
.next:
    inc ebx
    jmp .win
.done:
    pop rbx
    ret

wm_handle_input:
    xor eax, eax
    mov eax, [mouse_buttons]
    mov bl, [mouse_last]
    mov [mouse_last], al
    test al, 1
    jz .release
    test bl, 1
    jnz .skip_click
    mov eax, [mouse_x]
    mov ecx, [windows]
    add ecx, 12
    cmp eax, ecx
    jl .skip_click
    add ecx, 14
    cmp eax, ecx
    jge .skip_click
    mov eax, [mouse_y]
    mov ecx, [windows + 4]
    add ecx, 11
    cmp eax, ecx
    jl .skip_click
    add ecx, 14
    cmp eax, ecx
    jge .skip_click
    mov byte [windows + 20], 0
    mov byte [dragging], 0
    mov eax, 1
    ret
.skip_click:
    cmp byte [dragging], 1
    je .drag
    mov eax, [mouse_x]
    mov ecx, [windows]
    cmp eax, ecx
    jl .nochange
    mov edx, [windows + 8]
    add edx, ecx
    cmp eax, edx
    jge .nochange
    mov eax, [mouse_y]
    mov ecx, [windows + 4]
    cmp eax, ecx
    jl .nochange
    mov edx, ecx
    add edx, 26
    cmp eax, edx
    jge .nochange
    mov byte [dragging], 1
    mov eax, [mouse_x]
    sub eax, [windows]
    mov [drag_off_x], eax
    mov eax, [mouse_y]
    sub eax, [windows + 4]
    mov [drag_off_y], eax
    mov eax, 1
    ret
.drag:
    mov eax, [mouse_x]
    sub eax, [drag_off_x]
    cmp eax, 0
    jge .x_ok
    xor eax, eax
.x_ok:
    mov [windows], eax
    mov eax, [mouse_y]
    sub eax, [drag_off_y]
    cmp eax, 28
    jge .y_ok
    mov eax, 28
.y_ok:
    mov [windows + 4], eax
    mov eax, 1
    ret
.release:
    cmp byte [dragging], 1
    jne .nochange
    mov byte [dragging], 0
    mov eax, 1
    ret
.nochange:
    xor eax, eax
    ret

section .rodata
title_terminal: db "Navine Console", 0
