; Navine OS - Inter-Process Communication

[BITS 64]

global ipc_send
global ipc_recv
global ipc_init

section .bss
ipc_queue:      resb 4096

section .text
ipc_init:
    ret

ipc_send:
    mov rax, rsi
    ret

ipc_recv:
    xor rax, rax
    ret
