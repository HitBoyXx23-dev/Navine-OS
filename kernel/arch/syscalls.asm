; Navine OS - Syscall Interface

[BITS 64]

%include "constants.inc"

global init_syscalls
global syscall_handler

section .text
init_syscalls:
    mov ecx, 0xC0000082
    mov rax, syscall_handler
    wrmsr
    mov ecx, 0xC0000084
    xor eax, eax
    xor edx, edx
    wrmsr
    ret

syscall_handler:
    cmp byte [linux_mode_active], 1
    jne .navine
    call linux_syscall_translate
    cmp rax, -1
    je .bad
.navine:
    cmp rax, SYS_WRITE
    je near .write
    cmp rax, SYS_READ
    je near .read
    cmp rax, SYS_OPEN
    je near .open
    cmp rax, SYS_CLOSE
    je near .close
    cmp rax, SYS_EXIT
    je near .exit
    cmp rax, SYS_GETPID
    je near .getpid
    cmp rax, SYS_BRK
    je near .brk
    cmp rax, SYS_MMAP
    je near .mmap
    xor rax, rax
    sysret
.write:
    push rdx
    mov rdi, rsi
    call terminal_write
    pop rax
    sysret
.read:
    call vfs_read
    sysret
.open:
    mov rsi, 0
    call vfs_path_open
    sysret
.close:
    call vfs_close
    xor rax, rax
    sysret
.exit:
    call process_exit
    xor rax, rax
    sysret
.getpid:
    call current_pid
    sysret
.brk:
    call heap_brk
    sysret
.mmap:
    mov rax, rdi
    sysret
.bad:
    xor rax, rax
    sysret
