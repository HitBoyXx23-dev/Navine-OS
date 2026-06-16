; Navine OS - ext2 Read-Only Driver

[BITS 64]

global init_ext2
global ext2_read_file

section .text
init_ext2:
    ret

ext2_read_file:
    xor rax, rax
    ret
