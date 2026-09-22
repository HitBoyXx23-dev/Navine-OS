; Navine OS - Linux syscall translation table

[BITS 64]

%include "constants.inc"

global linux_syscall_init
global linux_syscall_translate
global linux_syscall_name

global linux_syscall_enable

section .bss
linux_sandbox_level: resb 1
linux_mode_active:   resb 1

section .text
linux_syscall_init:
    mov byte [linux_sandbox_level], 1
    mov byte [linux_mode_active], 0
    ret

linux_syscall_enable:
    mov byte [linux_mode_active], 1
    ret

linux_syscall_translate:
    cmp rax, 0
    je .read
    cmp rax, 1
    je .write
    cmp rax, 9
    je .mmap
    cmp rax, 12
    je .brk
    cmp rax, 60
    je .exit
    cmp rax, 59
    je .exec
    mov rax, 0xFFFFFFFF
    ret
.mmap:
    mov rax, SYS_MMAP
    ret
.brk:
    mov rax, SYS_BRK
    ret
.read:
    mov rax, SYS_READ
    ret
.write:
    mov rax, SYS_WRITE
    ret
.exit:
    mov rax, SYS_EXIT
    ret
.exec:
    mov rax, SYS_EXEC
    ret

linux_syscall_name:
    cmp rax, 0
    je .n0
    cmp rax, 1
    je .n1
    cmp rax, 59
    je .n59
    cmp rax, 60
    je .n60
    lea rax, [ls_name_unknown]
    ret
.n0:  lea rax, [name_read]; ret
.n1:  lea rax, [name_write]; ret
.n59: lea rax, [name_exec]; ret
.n60: lea rax, [name_exit]; ret

section .rodata
name_read:    db "read", 0
name_write:   db "write", 0
name_exec:    db "execve", 0
name_exit:    db "exit", 0
ls_name_unknown: db "unknown", 0
