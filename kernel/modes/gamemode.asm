; Navine OS - Game Mode (CPU/GPU priority, FPS overlay, background limiter)

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern fb_fill_rect
extern font_draw_string
extern fb_width
extern pit_ticks
extern scheduler_set_game_boost
%endif

global init_gamemode
global gamemode_enable
global gamemode_disable
global gamemode_toggle
global gamemode_is_active
global gamemode_render_overlay
global gamemode_apply_profile
global gamemode_tick_frame

section .bss
gamemode_active:    resb 1
gamemode_fps_last:  resq 1
gamemode_frame_cnt: resd 1
gamemode_fps:       resd 1
gamemode_bg_limit:  resb 1
fps_buf:            resb 16

section .text
init_gamemode:
    mov byte [gamemode_active], 0
    mov qword [gamemode_fps_last], 0
    mov dword [gamemode_frame_cnt], 0
    mov dword [gamemode_fps], 60
    mov byte [gamemode_bg_limit], 0
    call vulkan_init
    call hid_init
    call game_library_init
    ret

gamemode_enable:
    mov byte [gamemode_active], 1
    mov byte [gamemode_bg_limit], 1
    call gamemode_apply_profile
    call vulkan_optimize_for_gaming
    ret

gamemode_apply_profile:
    mov al, 1
    call scheduler_set_game_boost
    ret

gamemode_disable:
    mov byte [gamemode_active], 0
    mov byte [gamemode_bg_limit], 0
    xor al, al
    call scheduler_set_game_boost
    ret

gamemode_toggle:
    cmp byte [gamemode_active], 0
    je gamemode_enable
    jmp gamemode_disable

gamemode_is_active:
    movzx rax, byte [gamemode_active]
    ret

gamemode_tick_frame:
    inc dword [gamemode_frame_cnt]
    mov rax, [pit_ticks]
    sub rax, [gamemode_fps_last]
    cmp rax, 30
    jb .out
    mov eax, [gamemode_frame_cnt]
    imul eax, 33
    mov [gamemode_fps], eax
    mov dword [gamemode_frame_cnt], 0
    mov rax, [pit_ticks]
    mov [gamemode_fps_last], rax
    call gamemode_format_fps
.out:
    ret

gamemode_format_fps:
    lea rdi, [fps_buf]
    mov esi, [gamemode_fps]
    lea rdx, [label_fps_prefix]
.copy_prefix:
    movzx eax, byte [rdx]
    mov [rdi], al
    test al, al
    jz .digits
    inc rdi
    inc rdx
    jmp .copy_prefix
.digits:
    mov eax, esi
    cmp eax, 99
    jbe .fmt
    mov eax, 99
.fmt:
    mov ecx, 10
    xor edx, edx
    div ecx
    add dl, '0'
    mov [rdi + 1], dl
    add al, '0'
    mov [rdi], al
    mov byte [rdi + 2], 0
    ret

gamemode_render_overlay:
    call gamemode_tick_frame
    cmp byte [gamemode_active], 0
    je .done
    mov eax, [fb_width]
    sub eax, 160
    mov edi, eax
    mov esi, 8
    mov edx, 148
    mov ecx, 36
    mov r8d, 0xCC101820
    call fb_fill_rect
    mov edi, eax
    add edi, 10
    mov esi, 14
    lea rdx, [label_game_mode]
    mov ecx, 0xFF65D6FF
    call font_draw_string
    mov edi, eax
    add edi, 10
    mov esi, 30
    lea rdx, [fps_buf]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
.done:
    ret

section .rodata
label_game_mode:  db "GAME MODE", 0
label_fps_prefix: db "FPS:", 0
