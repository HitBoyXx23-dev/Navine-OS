; Navine OS - Intel e1000 Network Driver

[BITS 64]

global init_e1000
global e1000_send
global e1000_recv

section .text
init_e1000:
    ret

e1000_send:
    ret

e1000_recv:
    xor rax, rax
    ret
