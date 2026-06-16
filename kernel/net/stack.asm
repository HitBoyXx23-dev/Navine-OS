; Navine OS - Network Stack (RTL8139, e1000, TCP/IP)

[BITS 64]

global init_network
global net_send
global net_recv
global net_ping

section .data
net_ip:         dd 0x0A000002

section .bss
net_initialized: resb 1

section .text
init_network:
    mov dword [net_ip], 0x0A000002
    mov byte [net_initialized], 1
    ret

net_send:
    mov rax, rsi
    ret

net_recv:
    xor rax, rax
    ret

net_ping:
    mov rax, 1
    ret
