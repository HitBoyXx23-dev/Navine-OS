; kernel/entry.asm
; Language: NASM x86-64
; Purpose: ELF kernel entry for the future C17 kernel path.
; Build: nasm -f elf64 -o build/kernel/entry.o kernel/entry.asm

[BITS 64]

global _start
extern kernel_main
extern __bss_start
extern __bss_end

section .text
_start:
    ; Input: RDI points to NavineBootInfo from Stage 2.
    ; Side effects: clears BSS, switches to the C kernel stack, calls kernel_main.
    mov r12, rdi
    lea rsp, [rel kernel_stack_top]
    and rsp, -16

    lea rdi, [rel __bss_start]
    lea rcx, [rel __bss_end]
    sub rcx, rdi
    xor eax, eax
    rep stosb

    mov rdi, r12
    call kernel_main

.halt:
    cli
    hlt
    jmp .halt

section .bss
align 16
kernel_stack:
    resb 65536
kernel_stack_top:
