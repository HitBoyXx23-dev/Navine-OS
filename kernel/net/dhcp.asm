; Navine OS - DHCP client (VirtualBox NAT)

[BITS 64]

%include "constants.inc"

global dhcp_init
global dhcp_handle
global net_ip_addr
global net_has_ip
global net_get_ip

extern e1000_send
extern e1000_mac
extern net_poll

section .bss
net_ip_addr:    resd 1
net_has_ip:     resb 1
dhcp_xid:       resd 1

section .text
dhcp_init:
    mov dword [net_ip_addr], NET_IP_ADDR
    mov byte [net_has_ip], 1
    mov dword [dhcp_xid], 0x4E415649
    call dhcp_discover
    ret

net_get_ip:
    mov eax, [net_ip_addr]
    ret

dhcp_discover:
    mov rdi, NET_PKT_BUF_PHYS
    mov ecx, 6
    mov al, 0xFF
    rep stosb
    mov rsi, e1000_mac
    mov ecx, 6
    rep movsb
    mov word [rdi], 0x0008
    add rdi, 2
    mov byte [rdi], 0x45
    mov byte [rdi + 1], 0
    mov word [rdi + 2], 0x011C
    mov word [rdi + 4], 0
    mov byte [rdi + 8], 64
    mov byte [rdi + 9], 17
    mov word [rdi + 10], 0
    mov dword [rdi + 12], 0
    mov dword [rdi + 16], 0xFFFFFFFF
    add rdi, 20
    mov word [rdi], 0x4400
    mov word [rdi + 2], 0x4300
    mov word [rdi + 4], 0x01F4
    mov word [rdi + 6], 0
    add rdi, 8
    mov byte [rdi], 1
    mov byte [rdi + 1], 1
    mov eax, [dhcp_xid]
    mov [rdi + 4], eax
    mov word [rdi + 28], 0x0100
    add rdi, 240
    mov byte [rdi], 0x63
    mov byte [rdi + 1], 0x82
    mov byte [rdi + 2], 0x53
    mov byte [rdi + 3], 0x63
    mov byte [rdi + 4], 0x35
    mov byte [rdi + 5], 1
    mov byte [rdi + 6], 1
    mov byte [rdi + 7], 0xFF
    mov rsi, NET_PKT_BUF_PHYS
    mov edx, 318
    call e1000_send
    ret

dhcp_handle:
    mov rsi, NET_PKT_BUF_PHYS + 14
    movzx eax, byte [rsi]
    and eax, 0x0F
    shl eax, 2
    add rsi, rax
    add rsi, 8
    cmp byte [rsi], 2
    jne .out
    mov eax, [rsi + 16]
    test eax, eax
    jz .out
    mov [net_ip_addr], eax
    mov byte [net_has_ip], 1
.out:
    ret
