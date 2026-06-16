; Navine OS - ISO9660 Read-Only Driver

[BITS 64]

global init_iso9660
global iso9660_read_file

section .text
init_iso9660:
    ret

iso9660_read_file:
    xor rax, rax
    ret
