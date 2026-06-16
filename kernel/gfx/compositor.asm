; Navine OS - Compositor (direct framebuffer, no double buffer)

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern fb_base
extern fb_bpp
extern fb_width
extern fb_height
extern fb_pitch
extern fb_fill_rect
%endif

global init_compositor
global compositor_flip
global compositor_clear
global compositor_draw_window

section .bss
comp_initialized: resb 1
comp_real_fb:     resq 1

section .text
init_compositor:
    mov rax, [fb_base]
    mov [comp_real_fb], rax
    mov rax, COMPOSITOR_BACKBUFFER_PHYS
    mov [fb_base], rax
    mov byte [comp_initialized], 1
    ret

compositor_clear:
    jmp wallpaper_draw

compositor_flip:
    cmp byte [comp_initialized], 1
    jne .done
    cmp dword [fb_bpp], 32
    jne .done
    push rbx
    push r12
    push r13
    push r14
    mov r12, COMPOSITOR_BACKBUFFER_PHYS
    mov r13, [comp_real_fb]
    mov r14d, [fb_pitch]
    mov ebx, [fb_height]
.row:
    test ebx, ebx
    jz .out
    mov rsi, r12
    mov rdi, r13
    mov ecx, [fb_width]
    shr ecx, 1
    rep movsq
    add r12, r14
    add r13, r14
    dec ebx
    jmp .row
.out:
    pop r14
    pop r13
    pop r12
    pop rbx
.done:
    ret

compositor_draw_window:
    jmp fb_fill_rect
