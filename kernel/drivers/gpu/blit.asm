; kernel/drivers/gpu/blit.asm
; Language: NASM x86-64
; Purpose: Scalar blit routine placeholder for future AVX2 path.
[BITS 64]
global blit32_copy
section .text
blit32_copy:
    ; rdi=dst, rsi=src, rdx=dword count
    mov rcx, rdx
    rep movsd
    ret
