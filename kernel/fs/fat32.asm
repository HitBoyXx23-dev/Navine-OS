; Navine OS - FAT32 Read/Write Driver

[BITS 64]

global init_fat32
global fat32_read_file
global fat32_write_file

section .text
init_fat32:
    ret

fat32_read_file:
    xor rax, rax
    ret

fat32_write_file:
    xor rax, rax
    ret
