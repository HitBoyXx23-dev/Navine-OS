; Navine OS - Compatibility Layer (PE/DMG/HFS+)

[BITS 64]

global compat_init
global pe_load
global dmg_mount

section .text
compat_init:
    ret

pe_load:
    cmp word [rdi], 0x5A4D
    jne .fail
    mov rax, 1
    ret
.fail:
    xor rax, rax
    ret

dmg_mount:
    xor rax, rax
    ret
