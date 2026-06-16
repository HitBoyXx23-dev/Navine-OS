; Navine OS - Virtual Filesystem Layer

[BITS 64]

global init_vfs
global vfs_open
global vfs_read
global vfs_write
global vfs_close

section .bss
vfs_mounts:     resb 4096

section .text
init_vfs:
    ret

vfs_open:
    mov rax, 3
    ret

vfs_read:
    xor rax, rax
    ret

vfs_write:
    mov rax, rsi
    ret

vfs_close:
    ret
