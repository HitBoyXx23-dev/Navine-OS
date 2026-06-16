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
    cmp rax, SYS_WRITE
    je near .write
    cmp rax, SYS_READ
    je near .read
    cmp rax, SYS_EXIT
    je near .exit
    xor rax, rax
    sysret
.write:
    call sys_write
    sysret
.read:
    call sys_read
    sysret
.exit:
    call sys_exit
    sysret

sys_write:
    ret
sys_read:
    xor rax, rax
    ret
sys_exit:
    xor rax, rax
    ret
