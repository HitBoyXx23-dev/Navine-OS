; Navine OS - NavineFS Journaling Filesystem

[BITS 64]

%include "constants.inc"

global init_navinefs
global navinefs_format
global navinefs_read
global navinefs_write

section .bss
navinefs_super: resb 4096
navinefs_mounted: resb 1

section .text
init_navinefs:
    mov byte [navinefs_mounted], 0
    mov dword [navinefs_super], NAVINEFS_MAGIC
    mov dword [navinefs_super + 4], NAVINEFS_VERSION
    mov byte [navinefs_mounted], 1
    ret

navinefs_format:
    mov dword [navinefs_super], NAVINEFS_MAGIC
    mov dword [navinefs_super + 4], NAVINEFS_VERSION
    mov qword [navinefs_super + 8], 4096
    mov qword [navinefs_super + 16], 1024
    ret

navinefs_read:
    xor rax, rax
    ret

navinefs_write:
    mov rax, rdx
    ret
