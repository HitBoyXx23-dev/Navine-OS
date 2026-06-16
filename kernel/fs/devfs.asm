; Navine OS - /dev Virtual Filesystem

[BITS 64]

global init_devfs
global devfs_open

section .text
init_devfs:
    ret

devfs_open:
    mov rax, 1
    ret
