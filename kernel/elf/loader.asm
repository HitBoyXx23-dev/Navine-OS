; Navine OS - ELF64 Executable Loader

[BITS 64]

global elf_load
global elf_exec

section .text
elf_load:
    cmp dword [rdi], 0x464C457F
    jne .fail
    mov rax, 1
    ret
.fail:
    xor rax, rax
    ret

elf_exec:
    call elf_load
    ret
