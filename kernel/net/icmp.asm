; Navine OS - ICMP echo (ping)

[BITS 64]

%include "constants.inc"

global net_ping_host
global icmp_handle

section .text
net_ping_host:
    push rbx
    mov ebx, edi
    mov dword [icmp_replies], 0
    call net_tx_icmp
    mov ecx, 100000
.wait:
    call net_poll
    cmp dword [icmp_replies], 0
    jne .ok
    dec ecx
    jnz .wait
    xor eax, eax
    jmp .out
.ok:
    mov eax, 1
.out:
    pop rbx
    ret

net_tx_icmp:
    call net_ensure_gateway
    mov rdi, NET_PKT_BUF_PHYS
    mov rsi, net_gateway_mac
    mov ecx, 6
    rep movsb
    mov rsi, e1000_mac
    mov ecx, 6
    rep movsb
    mov word [rdi], 0x0008
    add rdi, 2
    mov byte [rdi], 0x45
    mov byte [rdi + 1], 0
    mov word [rdi + 2], 0x001C
    mov word [rdi + 4], 0
    mov byte [rdi + 8], 64
    mov byte [rdi + 9], 1
    mov word [rdi + 10], 0
    mov eax, [net_ip_addr]
    mov [rdi + 12], eax
    mov eax, ebx
    mov [rdi + 16], eax
    add rdi, 20
    mov byte [rdi], 8
    mov byte [rdi + 1], 0
    inc word [icmp_seq]
    mov ax, [icmp_seq]
    xchg al, ah
    mov word [rdi + 6], ax
    mov byte [rdi + 8], 0x4E
    mov byte [rdi + 9], 0x56
    mov rsi, NET_PKT_BUF_PHYS
    mov edx, 42
    call e1000_send
    ret

icmp_handle:
    mov rsi, NET_PKT_BUF_PHYS + 14
    movzx eax, byte [rsi]
    and eax, 0x0F
    shl eax, 2
    add rsi, rax
    cmp byte [rsi], 0
    jne .out
    cmp byte [rsi + 8], 0
    jne .out
    inc dword [icmp_replies]
.out:
    ret

section .bss
icmp_seq:       resw 1
icmp_replies:   resd 1
