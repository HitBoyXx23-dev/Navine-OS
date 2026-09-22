; Navine OS - Desktop Wallpaper

[BITS 64]

%include "constants.inc"

global init_wallpaper
global wallpaper_draw

%ifndef NAVINE_LINK_BUILD
extern ata_read_sectors
%endif

section .bss
wallpaper_loaded: resb 1

section .text
init_wallpaper:
    mov byte [wallpaper_loaded], 0
    ret

%define WP_TOP_R 0x12
%define WP_TOP_G 0x1E
%define WP_TOP_B 0x36
%define WP_BOT_R 0x05
%define WP_BOT_G 0x08
%define WP_BOT_B 0x12

wallpaper_draw:
    cmp byte [wallpaper_loaded], 1
    jne .gradient
    cmp dword [fb_bpp], 32
    jne .gradient
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, WALLPAPER_PHYS
    mov r13, [fb_base]
    mov r14d, [fb_pitch]
    mov ebx, [fb_height]
    cmp ebx, WALLPAPER_SRC_H
    jbe .have_rows
    mov ebx, WALLPAPER_SRC_H
.have_rows:
    mov r15d, [fb_width]
    cmp r15d, WALLPAPER_SRC_W
    jbe .row
    mov r15d, WALLPAPER_SRC_W
.row:
    test ebx, ebx
    jz .blit_done
    mov rsi, r12
    mov rdi, r13
    mov ecx, r15d
.col:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .col
    add r12, WALLPAPER_SRC_W * 4
    add r13, r14
    dec ebx
    jmp .row
.blit_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.gradient:
    push rbx
    push r13
    push r14
    push r15
    mov r14d, [fb_height]
    test r14d, r14d
    jz .grad_done
    xor r15d, r15d
.grad_row:
    cmp r15d, r14d
    jae .grad_done
    mov eax, r15d
    shl eax, 8
    xor edx, edx
    div r14d
    mov r13d, eax
    mov ebx, 0xFF000000
    mov eax, WP_BOT_R - WP_TOP_R
    imul eax, r13d
    sar eax, 8
    add eax, WP_TOP_R
    and eax, 0xFF
    shl eax, 16
    or ebx, eax
    mov eax, WP_BOT_G - WP_TOP_G
    imul eax, r13d
    sar eax, 8
    add eax, WP_TOP_G
    and eax, 0xFF
    shl eax, 8
    or ebx, eax
    mov eax, WP_BOT_B - WP_TOP_B
    imul eax, r13d
    sar eax, 8
    add eax, WP_TOP_B
    and eax, 0xFF
    or ebx, eax
    mov edi, 0
    mov esi, r15d
    mov edx, [fb_width]
    mov ecx, 1
    mov r8d, ebx
    call fb_fill_rect
    inc r15d
    jmp .grad_row
.grad_done:
    pop r15
    pop r14
    pop r13
    pop rbx
    ret
