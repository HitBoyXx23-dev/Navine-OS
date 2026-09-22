; Navine OS - On-screen kernel panic

[BITS 64]

%include "constants.inc"

global kernel_panic

%ifndef NAVINE_LINK_BUILD
extern fb_base
extern fb_width
extern fb_bpp
extern serial_puts
%endif

section .text
kernel_panic:
    cli
    test rsi, rsi
    jz .screen
    call serial_puts
.screen:
    mov rax, FB_INFO_PHYS
    mov r8, [rax]
    test r8, r8
    jz .halt
    movzx r9d, word [rax + FB_INFO_BPP_OFF]
    cmp r9d, 32
    jne .halt
    movzx r11d, word [rax + 8]
    test r11d, r11d
    jz .halt
    mov r10d, [rax + 16]
    test r10d, r10d
    jnz .have_pitch
    mov r10d, r11d
    shl r10d, 2
.have_pitch:
    xor ebx, ebx
.row:
    cmp ebx, 64
    jge .halt
    mov eax, ebx
    imul rax, r10
    mov rdi, r8
    add rdi, rax
    mov ecx, r11d
    mov eax, 0xFF2020A0
    rep stosd
    inc ebx
    jmp .row
.halt:
    hlt
    jmp .halt
