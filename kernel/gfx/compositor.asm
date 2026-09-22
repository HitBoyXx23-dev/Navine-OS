; Navine OS - Compositor (back-buffer with dirty regions)

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
global compositor_mark_dirty
global compositor_enable_backbuffer
global compositor_wait_vblank

section .bss
comp_initialized: resb 1
comp_real_fb:     resq 1
comp_dirty:       resb 1
comp_dirty_y0:    resd 1
comp_dirty_y1:    resd 1
comp_use_hw:      resb 1

section .text
init_compositor:
    mov rax, [fb_base]
    test rax, rax
    jnz .have
    mov rax, FB_INFO_PHYS
    mov rax, [rax]
    test rax, rax
    jnz .have
    mov rax, 0xE0000000
.have:
    mov [comp_real_fb], rax
    mov [fb_base], rax
    mov byte [comp_initialized], 0
    mov byte [comp_use_hw], 1
    mov byte [comp_dirty], 1
    mov dword [comp_dirty_y0], 0
    mov eax, [fb_height]
    mov [comp_dirty_y1], eax
    ret

compositor_enable_backbuffer:
    cmp byte [comp_use_hw], 0
    je .done
    mov rax, [comp_real_fb]
    mov [comp_real_fb], rax
    mov rax, COMPOSITOR_BACKBUFFER_PHYS
    mov [fb_base], rax
    mov byte [comp_initialized], 1
    mov byte [comp_use_hw], 0
    mov byte [comp_dirty], 1
.done:
    ret

compositor_mark_dirty:
    mov byte [comp_dirty], 1
    mov dword [comp_dirty_y0], 0
    mov eax, [fb_height]
    mov [comp_dirty_y1], eax
    ret

compositor_wait_vblank:
    push rcx
    push rdx
    mov ecx, 0x100000
.leave_retrace:
    mov dx, 0x3DA
    in al, dx
    test al, 0x08
    jz .enter_retrace
    dec ecx
    jnz .leave_retrace
    jmp .out
.enter_retrace:
    mov ecx, 0x100000
.scan:
    mov dx, 0x3DA
    in al, dx
    test al, 0x08
    jnz .out
    dec ecx
    jnz .scan
.out:
    pop rdx
    pop rcx
    ret

compositor_clear:
    call compositor_mark_dirty
    jmp wallpaper_draw

compositor_flip:
    cmp byte [comp_use_hw], 1
    je .done
    cmp byte [comp_initialized], 1
    jne .done
    cmp byte [comp_dirty], 0
    je .done
    call compositor_wait_vblank
    cmp dword [fb_bpp], 32
    je .flip32
    cmp dword [fb_bpp], 24
    je .flip24
    jmp .done
.flip32:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, COMPOSITOR_BACKBUFFER_PHYS
    mov r13, [comp_real_fb]
    mov r14d, [fb_pitch]
    mov ebx, [comp_dirty_y0]
    mov r15d, [comp_dirty_y1]
.row:
    cmp ebx, r15d
    jge .out
    mov eax, ebx
    imul rax, r14
    mov rsi, r12
    add rsi, rax
    mov rdi, r13
    add rdi, rax
    mov ecx, [fb_width]
    shr ecx, 1
    rep movsq
    inc ebx
    jmp .row
.out:
    mov byte [comp_dirty], 0
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    jmp .done
.flip24:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, COMPOSITOR_BACKBUFFER_PHYS
    mov r13, [comp_real_fb]
    mov r14d, [fb_pitch]
    mov ebx, [comp_dirty_y0]
    mov r15d, [comp_dirty_y1]
.row24:
    cmp ebx, r15d
    jge .out24
    mov eax, ebx
    imul rax, r14
    mov rsi, r12
    add rsi, rax
    mov rdi, r13
    add rdi, rax
    mov ecx, [fb_width]
    imul ecx, 3
    rep movsb
    inc ebx
    jmp .row24
.out24:
    mov byte [comp_dirty], 0
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
.done:
    ret

compositor_draw_window:
    call compositor_mark_dirty
    jmp fb_fill_rect
