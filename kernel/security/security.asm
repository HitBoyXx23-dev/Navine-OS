; Navine OS - Security Subsystem

[BITS 64]

global security_init
global security_check_syscall
global aslr_apply

section .text
security_init:
    ret

security_check_syscall:
    mov rax, 1
    ret

aslr_apply:
    ret
