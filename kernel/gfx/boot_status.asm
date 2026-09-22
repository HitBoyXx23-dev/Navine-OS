; Navine OS - Early boot banner (no font driver)

[BITS 64]

%include "constants.inc"

global boot_status_draw
global boot_status_ready

section .bss
fb_base_boot: resq 1
fb_pitch_boot: resd 1

section .text
boot_status_draw:
    call boot_cache_fb
    mov r8d, 20
    mov r9d, 20
    mov r10d, 320
    mov r11d, 48
    mov r12d, 0xFFFFFFFF
    call boot_fill_box
    mov r8d, 20
    mov r9d, 80
    mov r10d, 420
    mov r11d, 24
    mov r12d, 0xFF65D6FF
    call boot_fill_box
    ret

boot_status_ready:
    call boot_cache_fb
    mov r8d, 20
    mov r9d, 140
    mov r10d, 520
    mov r11d, 28
    mov r12d, 0xFF90EE90
    call boot_fill_box
    ret

boot_cache_fb:
    mov rax, FB_INFO_PHYS
    mov rdi, [rax]
    mov [rel fb_base_boot], rdi
    mov eax, [rax + 16]
    test eax, eax
    jnz .have_pitch
    mov eax, VESA_WIDTH * 4
.have_pitch:
    mov [rel fb_pitch_boot], eax
    ret

boot_fill_box:
    mov rdi, [rel fb_base_boot]
    test rdi, rdi
    jz .out
    cmp rdi, 0x00F00000
    jb .out
    mov eax, r9d
    imul eax, [rel fb_pitch_boot]
    mov ebx, r8d
    shl ebx, 2
    add eax, ebx
    add rdi, rax
    mov ebx, r11d
.row:
    test ebx, ebx
    jz .out
    push rdi
    mov ecx, r10d
    mov eax, r12d
    rep stosd
    pop rdi
    mov eax, [rel fb_pitch_boot]
    add rdi, rax
    dec ebx
    jmp .row
.out:
    ret
