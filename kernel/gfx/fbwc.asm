; Navine OS - Framebuffer write-combining via variable MTRR

[BITS 64]

%include "constants.inc"

global setup_fb_writecombine

section .text
setup_fb_writecombine:
    mov rax, FB_INFO_PHYS
    cmp byte [rax + FB_INFO_GFX_OK], 1
    je .done
    mov rax, [rax]
    test rax, rax
    jz .done

    push rbx
    mov eax, 1
    cpuid
    test edx, 1 << 12
    pop rbx
    jz .done

    mov rax, cr0
    or eax, 1 << 30
    and eax, ~(1 << 29)
    mov cr0, rax
    wbinvd

    mov ecx, 0x200
    mov rax, FB_INFO_PHYS
    mov eax, [rax]
    and eax, 0xF0000000
    or eax, 0x01
    xor edx, edx
    wrmsr

    mov ecx, 0x201
    mov eax, 0xF0000800
    mov edx, 0x0000000F
    wrmsr

    mov ecx, 0x2FF
    rdmsr
    or eax, 0x800
    wrmsr

    wbinvd
    mov rax, cr0
    and eax, ~(1 << 30)
    mov cr0, rax
.done:
    ret
