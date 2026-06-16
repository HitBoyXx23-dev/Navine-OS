; Navine OS - Sign in / Sign up screen

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern fb_fill_rect
extern font_draw_string
extern keyboard_read
extern keyboard_has_data
extern fb_width
extern fb_height
%endif

global init_login
global login_render
global login_poll
global login_completed

section .bss
login_completed:    resb 1
login_mode:         resb 1
username_len:       resd 1
username_buf:       resb 32

section .text
init_login:
    mov byte [login_completed], 1
    mov byte [login_mode], 0
    mov dword [username_len], 6
    lea rdi, [username_buf]
    mov rax, 0x656E6976614E
    mov [rdi], rax
    mov byte [rdi + 6], 0
    ret

login_render:
    mov edi, 0
    mov esi, 0
    mov edx, [fb_width]
    mov ecx, [fb_height]
    mov r8d, 0xFF0A0A12
    call fb_fill_rect
    mov eax, [fb_width]
    sub eax, 420
    shr eax, 1
    mov r12d, eax
    mov eax, [fb_height]
    sub eax, 320
    shr eax, 1
    mov r13d, eax
    mov edi, r12d
    mov esi, r13d
    mov edx, 420
    mov ecx, 320
    mov r8d, COLOR_NAVINE_GRAY
    call fb_fill_rect
    mov edi, r12d
    add edi, 24
    mov esi, r13d
    add esi, 24
    lea rdx, [title_navine]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, r12d
    add edi, 24
    mov esi, r13d
    add esi, 56
    cmp byte [login_mode], 0
    je .signin_tab
    lea rdx, [tab_signin]
    mov ecx, 0xFF888888
    call font_draw_string
    mov edi, r12d
    add edi, 144
    mov esi, r13d
    add esi, 56
    lea rdx, [tab_signup]
    mov ecx, COLOR_NAVINE_BLUE
    call font_draw_string
    jmp .tabs_done
.signin_tab:
    lea rdx, [tab_signin]
    mov ecx, COLOR_NAVINE_BLUE
    call font_draw_string
    mov edi, r12d
    add edi, 144
    mov esi, r13d
    add esi, 56
    lea rdx, [tab_signup]
    mov ecx, 0xFF888888
    call font_draw_string
.tabs_done:
    mov edi, r12d
    add edi, 24
    mov esi, r13d
    add esi, 100
    lea rdx, [label_user]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, r12d
    add edi, 24
    mov esi, r13d
    add esi, 130
    mov edx, 372
    mov ecx, 36
    mov r8d, 0xFF1C1C1E
    call fb_fill_rect
    mov edi, r12d
    add edi, 32
    mov esi, r13d
    add esi, 138
    lea rdx, [username_buf]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, r12d
    add edi, 24
    mov esi, r13d
    add esi, 200
    lea rdx, [hint_enter]
    mov ecx, 0xFFAAAAAA
    call font_draw_string
    mov edi, r12d
    add edi, 24
    mov esi, r13d
    add esi, 240
    lea rdx, [hint_tab]
    mov ecx, 0xFF888888
    call font_draw_string
    ret

login_poll:
    call keyboard_has_data
    test rax, rax
    jz .done
    call keyboard_read
    cmp al, 0x1C
    je .enter
    cmp al, 0x0F
    je .tab
    cmp al, 0x0E
    je .backspace
    cmp al, 32
    jb .done
    cmp al, 126
    ja .done
    mov ecx, [username_len]
    cmp ecx, 31
    jae .done
    lea rdi, [username_buf]
    add rdi, rcx
    mov [rdi], al
    inc dword [username_len]
    mov byte [rdi + 1], 0
    jmp .done
.backspace:
    cmp dword [username_len], 0
    je .done
    dec dword [username_len]
    lea rdi, [username_buf]
    add rdi, [username_len]
    mov byte [rdi], 0
    jmp .done
.tab:
    xor byte [login_mode], 1
    jmp .done
.enter:
    cmp dword [username_len], 0
    je .done
    mov byte [login_completed], 1
.done:
    ret

section .rodata
title_navine: db "Navine OS", 0
tab_signin:   db "Sign In", 0
tab_signup:   db "Sign Up", 0
label_user:   db "Username", 0
hint_enter:   db "Press Enter to continue", 0
hint_tab:     db "Tab: switch Sign In / Sign Up", 0
