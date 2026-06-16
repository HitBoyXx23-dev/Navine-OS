[BITS 64]

section .bss
align 16
resb 65536
stack_top:

section .text
global _navine_crt_start
_navine_crt_start:
    mov rsp, stack_top
    lea rdi, [rel __bss_start]
    lea rcx, [rel __bss_end]
    sub rcx, rdi
    xor eax, eax
    rep stosb
    extern main
    xor ecx, ecx
    xor edx, edx
    call main
.hang:
    hlt
    jmp .hang

extern __bss_start
extern __bss_end
