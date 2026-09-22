; Navine OS - Paint framebuffer before full driver init

[BITS 64]

%include "constants.inc"

global early_framebuffer_paint
global boot_fb_ensure

section .text
boot_fb_ensure:
    mov rax, FB_INFO_PHYS
    cmp qword [rax], 0
    jne .done
    mov rbx, 0xE0000000
    mov [rax], rbx
    mov dword [rax + 8], VESA_WIDTH
    mov dword [rax + 12], VESA_HEIGHT
    mov dword [rax + 16], VESA_WIDTH * 4
    mov dword [rax + FB_INFO_BPP_OFF], VESA_BPP
.done:
    ret

early_framebuffer_paint:
    push rbx
    push r12
    mov rax, FB_INFO_PHYS
    mov r12, [rax]
    test r12, r12
    jz .done
    cmp r12, 0x00F00000
    jb .done
    movzx r10d, word [rax + FB_INFO_BPP_OFF]
    movzx r8d, word [rax + 8]
    test r8d, r8d
    jnz .have_w
    mov r8d, VESA_WIDTH
.have_w:
    movzx r9d, word [rax + 12]
    test r9d, r9d
    jnz .have_h
    mov r9d, VESA_HEIGHT
.have_h:
    mov r11d, [rax + 16]
    test r11d, r11d
    jnz .have_pitch
    mov r11d, r8d
    cmp r10d, 8
    je .have_pitch
    cmp r10d, 24
    je .pitch24
    shl r11d, 2
    jmp .have_pitch
.pitch24:
    imul r11d, 3
.have_pitch:
    xor ebx, ebx
.row:
    cmp ebx, r9d
    jge .done
    mov eax, ebx
    imul rax, r11
    mov rdi, r12
    add rdi, rax
    mov ecx, r8d
    cmp r10d, 8
    je .row8
    cmp r10d, 24
    je .row24
    mov eax, 0xFF105080
    rep stosd
    jmp .next
.row8:
    mov al, 9
    rep stosb
    jmp .next
.row24:
    test ecx, ecx
    jz .next
    mov byte [rdi], 0x80
    mov byte [rdi + 1], 0x50
    mov byte [rdi + 2], 0x10
    add rdi, 3
    dec ecx
    jmp .row24
.next:
    inc ebx
    jmp .row
.done:
    pop r12
    pop rbx
    ret
