; Navine OS - Network Stack

[BITS 64]

%include "constants.inc"

global init_network
global net_send
global net_recv
global net_ping
global net_is_ready
global kernel_net_tick
global net_irq_pending

section .data
net_ip:         dd NET_IP_ADDR

section .bss
net_initialized: resb 1
net_driver:      resb 1
net_irq_pending: resb 1

section .text
init_network:
    call init_pci
    call init_e1000
    call e1000_link_up
    test rax, rax
    jz .no_nic
    call internet_init
    mov byte [net_driver], 1
    mov byte [net_initialized], 1
    ret
.no_nic:
    mov byte [net_driver], 0
    mov byte [net_initialized], 1
    ret

net_is_ready:
    cmp byte [net_driver], 1
    jne .no
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

net_send:
    cmp byte [net_driver], 1
    jne .noop
    call e1000_send
    ret
.noop:
    mov rax, rsi
    ret

net_recv:
    cmp byte [net_driver], 1
    jne .zero
    call e1000_recv
    ret
.zero:
    xor rax, rax
    ret

net_ping:
    cmp byte [net_initialized], 0
    je .fail
    cmp byte [net_driver], 0
    je .fail
    mov rax, 1
    ret
.fail:
    xor rax, rax
    ret

kernel_net_tick:
    mov byte [net_irq_pending], 1
    ret
