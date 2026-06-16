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
    cmp byte [wallpaper_loaded], 1
    je .done
    mov rdi, WALLPAPER_LBA
    mov rsi, WALLPAPER_PHYS
    mov rdx, WALLPAPER_SECTORS
    call ata_read_sectors
    mov byte [wallpaper_loaded], 1
.done:
    ret

wallpaper_draw:
    cmp byte [wallpaper_loaded], 1
    jne .solid
    cmp dword [fb_bpp], 32
    jne .solid
    mov eax, [fb_width]
    cmp eax, VESA_WIDTH
    jne .solid
    mov eax, [fb_height]
    cmp eax, VESA_HEIGHT
    jne .solid
    push rbx
    push r12
    push r13
    push r14
    mov r12, WALLPAPER_PHYS
    mov r13, [fb_base]
    mov r14d, [fb_pitch]
    mov ebx, VESA_HEIGHT
.row:
    mov rsi, r12
    mov rdi, r13
    mov ecx, VESA_WIDTH
.col:
    mov eax, [rsi]
    mov [rdi], eax
    add rsi, 4
    add rdi, 4
    dec ecx
    jnz .col
    add r12, VESA_WIDTH * 4
    add r13, r14
    dec ebx
    jnz .row
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.solid:
    mov edi, 0
    mov esi, 0
    mov edx, [fb_width]
    mov ecx, [fb_height]
    mov r8d, 0xFF0B2545
    call fb_fill_rect
    ret
