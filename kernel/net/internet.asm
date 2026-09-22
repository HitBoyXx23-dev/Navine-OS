; Navine OS - IPv4 client (ARP, DNS, TCP, HTTP)

[BITS 64]

%include "constants.inc"

global internet_init
global net_poll
global net_dns_resolve
global net_http_get
global net_https_probe
global net_fetch_title
global net_fetch_lines
global net_fetch_count
global net_rx_len
global net_gateway_mac
global net_fill_eth
global net_fill_ipv4
global net_tcp_rx_len
global net_http_slot
global net_ws_slot
global net_tcp_slot

section .bss
net_rx_len:          resd 1
net_gateway_mac:     resb 6
net_arp_pending:     resd 1
net_dns_pending:     resb 1
net_dns_result:      resd 1
net_tcp_state:       resb 1
net_tcp_seq:           resd 1
net_tcp_ack:           resd 1
net_tcp_remote_ip:     resd 1
net_tcp_remote_port:   resw 1
net_tcp_local_port:    resw 1
net_tcp_rx_len:        resd 1
net_http_done:         resb 1
net_tcp_retx:          resb 1
net_tcp_syn_tick:      resd 1
net_tcp_slot:          resb 1
net_fetch_count:       resd 1
net_fetch_title:       resb 64
net_fetch_lines:       resq 24
net_host_buf:          resb 128
net_path_buf:          resb 128
net_http_buf:          resb 512

section .text
internet_init:
    lea rdi, [net_gateway_mac]
    xor eax, eax
    mov ecx, 6
    rep stosb
    mov dword [net_arp_pending], NET_GATEWAY
    mov byte [net_dns_pending], 0
    mov byte [net_tcp_state], 0
    mov word [net_tcp_local_port], 0xC000
    mov byte [net_tcp_slot], 0
    mov dword [net_fetch_count], 0
    call dhcp_init
    mov dword [net_arp_pending], NET_GATEWAY
    call net_tx_arp
    mov ecx, 5000
.wait_gw:
    call net_poll
    mov al, [net_gateway_mac]
    test al, al
    jnz .gw_ok
    call net_tx_arp
    dec ecx
    jnz .wait_gw
.gw_ok:
    ret

net_ensure_gateway:
    mov al, [net_gateway_mac]
    test al, al
    jnz .ok
    mov dword [net_arp_pending], NET_GATEWAY
    call net_tx_arp
    mov ecx, 20000
.wait:
    call net_poll
    mov al, [net_gateway_mac]
    test al, al
    jnz .ok
    dec ecx
    jnz .wait
.ok:
    ret

net_poll:
    call net_tcp_check_retx
    mov ecx, 16
.loop:
    call e1000_recv
    test rax, rax
    jz .done
    call net_dispatch
    dec ecx
    jnz .loop
.done:
    ret

net_dispatch:
    mov rsi, NET_PKT_BUF_PHYS
    cmp word [rsi + 12], 0x0608
    je net_rx_arp
    cmp word [rsi + 12], 0x0008
    je net_rx_ipv4
    ret

net_rx_arp:
    mov rsi, NET_PKT_BUF_PHYS
    cmp word [rsi + 20], 0x0200
    jne .out
    mov eax, [net_arp_pending]
    test eax, eax
    jz .out
    cmp eax, [rsi + 28]
    jne .out
    lea rdi, [net_gateway_mac]
    add rsi, 22
    mov ecx, 6
    rep movsb
    mov dword [net_arp_pending], 0
.out:
    ret

net_rx_ipv4:
    movzx eax, byte [NET_PKT_BUF_PHYS + 14]
    and eax, 0x0F
    shl eax, 2
    mov rsi, NET_PKT_BUF_PHYS + 14
    add rsi, rax
    movzx eax, byte [rsi]
    cmp al, 17
    je net_rx_udp
    cmp al, 1
    je net_rx_icmp
    cmp al, 6
    je net_rx_tcp
    ret

net_rx_icmp:
    call icmp_handle
    ret

net_rx_udp:
    movzx ecx, word [rsi + 2]
    rol cx, 8
    cmp cx, 68
    je .dhcp
    movzx ecx, word [rsi]
    rol cx, 8
    cmp cx, 0x0400
    jne .out
    cmp byte [net_dns_pending], 1
    jne .out
    lea rdi, [rsi + 8]
    call net_parse_dns
    jmp .out
.dhcp:
    call dhcp_handle
.out:
    ret

net_parse_dns:
    add rdi, 12
.skip:
    movzx eax, byte [rdi]
    test al, al
    jz .hdr
    cmp al, 0xC0
    jae .hdr
    inc rdi
    add rdi, rax
    jmp .skip
.hdr:
    add rdi, 5
    cmp word [rdi - 2], 0x0100
    jne .fail
    mov eax, [rdi + 10]
    mov [net_dns_result], eax
    mov byte [net_dns_pending], 0
.fail:
    ret

net_rx_tcp:
    mov eax, [rsi + 4]
    bswap eax
    mov [net_tcp_ack], eax
    movzx eax, byte [rsi + 12]
    shr eax, 4
    shl eax, 2
    mov r8, rsi
    add r8, rax
    movzx eax, byte [r8 + 13]
    test al, 0x02
    jz .not_syn
    test al, 0x10
    jz .not_syn
    mov byte [net_tcp_state], 2
    inc dword [net_tcp_seq]
    call net_tx_tcp_ack
    ret
.not_syn:
    cmp byte [net_tcp_state], 2
    jne .out
    test al, 0x08
    jz .out
    movzx ecx, word [rsi + 2]
    rol cx, 8
    sub ecx, eax
    jc .out
    cmp ecx, 0
    je .out
    lea rdi, [NET_FETCH_BUF_PHYS]
    add rdi, [net_tcp_rx_len]
    lea rsi, [r8 + 20]
    cmp byte [net_tcp_slot], 1
    je .ws_rx
    cmp word [net_tcp_remote_port], 0xBB01
    je .tls_rx
    rep movsb
    add [net_tcp_rx_len], ecx
    add [net_tcp_ack], ecx
    call net_tx_tcp_ack
    mov byte [net_http_done], 1
    jmp .out
.tls_rx:
    mov esi, ecx
    call tls_feed
    add [net_tcp_ack], ecx
    call net_tx_tcp_ack
    mov byte [net_http_done], 1
    jmp .out
.ws_rx:
    mov esi, ecx
    call ws_feed
    add [net_tcp_ack], ecx
    call net_tx_tcp_ack
.out:
    ret

net_tx_arp:
    mov rdi, NET_PKT_BUF_PHYS
    mov ecx, 6
    xor eax, eax
    rep stosb
    mov dword [rdi], 0xFFFFFFFF
    add rdi, 4
    mov rsi, e1000_mac
    mov ecx, 6
    rep movsb
    mov word [rdi], 0x0608
    add rdi, 2
    mov word [rdi], 0x0100
    mov word [rdi + 2], 0x0604
    mov word [rdi + 4], 0x0100
    mov word [rdi + 6], 0
    add rdi, 8
    mov rsi, e1000_mac
    mov ecx, 6
    rep movsb
    mov eax, NET_IP_ADDR
    mov [rdi], eax
    mov eax, [net_arp_pending]
    mov [rdi + 4], eax
    mov rsi, NET_PKT_BUF_PHYS
    mov edx, 42
    call e1000_send
    ret

net_tx_udp:
    call net_ensure_gateway
    push rbx
    mov rbx, rdx
    mov cl, 17
    mov rsi, NET_PKT_BUF_PHYS
    call net_fill_eth
    mov edi, NET_DNS
    mov edx, ebx
    add dx, 28
    call net_fill_ipv4
    pop rbx
    mov rsi, NET_PKT_BUF_PHYS
    movzx edx, word [NET_PKT_BUF_PHYS + 16]
    rol dx, 8
    call e1000_send
    ret

net_tx_tcp_ack:
    mov cl, 6
    mov rsi, NET_PKT_BUF_PHYS
    call net_fill_eth
    mov edi, [net_tcp_remote_ip]
    mov edx, 40
    call net_fill_ipv4
    mov ax, word [net_tcp_local_port]
    mov word [NET_PKT_BUF_PHYS + 34], ax
    mov ax, word [net_tcp_remote_port]
    xchg al, ah
    mov word [NET_PKT_BUF_PHYS + 36], ax
    mov eax, [net_tcp_seq]
    bswap eax
    mov [NET_PKT_BUF_PHYS + 38], eax
    mov eax, [net_tcp_ack]
    bswap eax
    mov [NET_PKT_BUF_PHYS + 42], eax
    mov byte [NET_PKT_BUF_PHYS + 47], 0x50
    mov byte [NET_PKT_BUF_PHYS + 53], 0x10
    mov word [NET_PKT_BUF_PHYS + 50], 0
    mov edx, 40
    mov rsi, NET_PKT_BUF_PHYS + 34
    xor ecx, ecx
    call net_tcp_csum
    mov [NET_PKT_BUF_PHYS + 50], ax
    mov edx, 40
    mov rsi, NET_PKT_BUF_PHYS
    call e1000_send
    ret

net_tx_tcp_syn:
    call net_ensure_gateway
    mov cl, 6
    mov rsi, NET_PKT_BUF_PHYS
    call net_fill_eth
    mov edi, [net_tcp_remote_ip]
    mov edx, 40
    call net_fill_ipv4
    mov ax, word [net_tcp_local_port]
    mov word [NET_PKT_BUF_PHYS + 34], ax
    mov ax, word [net_tcp_remote_port]
    xchg al, ah
    mov word [NET_PKT_BUF_PHYS + 36], ax
    mov eax, [net_tcp_seq]
    bswap eax
    mov [NET_PKT_BUF_PHYS + 38], eax
    mov dword [NET_PKT_BUF_PHYS + 42], 0
    mov byte [NET_PKT_BUF_PHYS + 47], 0x50
    mov byte [NET_PKT_BUF_PHYS + 53], 0x02
    mov word [NET_PKT_BUF_PHYS + 50], 0
    mov edx, 40
    mov rsi, NET_PKT_BUF_PHYS + 34
    mov ecx, 20
    call net_tcp_csum
    mov [NET_PKT_BUF_PHYS + 50], ax
    mov edx, 40
    mov rsi, NET_PKT_BUF_PHYS
    call e1000_send
    ret

net_tx_tcp_data:
    mov r12, rsi
    mov r13d, edx
    mov cl, 6
    mov rsi, NET_PKT_BUF_PHYS
    call net_fill_eth
    mov edi, [net_tcp_remote_ip]
    lea edx, [r13d + 40]
    call net_fill_ipv4
    mov ax, word [net_tcp_local_port]
    mov word [NET_PKT_BUF_PHYS + 34], ax
    mov ax, word [net_tcp_remote_port]
    xchg al, ah
    mov word [NET_PKT_BUF_PHYS + 36], ax
    mov eax, [net_tcp_seq]
    bswap eax
    mov [NET_PKT_BUF_PHYS + 38], eax
    mov eax, [net_tcp_ack]
    bswap eax
    mov [NET_PKT_BUF_PHYS + 42], eax
    mov byte [NET_PKT_BUF_PHYS + 47], 0x50
    mov byte [NET_PKT_BUF_PHYS + 53], 0x18
    mov word [NET_PKT_BUF_PHYS + 50], 0
    mov rdi, NET_PKT_BUF_PHYS + 54
    mov rsi, r12
    mov ecx, r13d
    rep movsb
    mov rsi, NET_PKT_BUF_PHYS
    movzx edx, word [NET_PKT_BUF_PHYS + 16]
    rol dx, 8
    mov ecx, r13d
    add ecx, 20
    mov edx, ecx
    mov rsi, NET_PKT_BUF_PHYS + 34
    xor ecx, ecx
    call net_tcp_csum
    mov [NET_PKT_BUF_PHYS + 50], ax
    mov rsi, NET_PKT_BUF_PHYS
    movzx edx, word [NET_PKT_BUF_PHYS + 16]
    rol dx, 8
    call e1000_send
    add [net_tcp_seq], r13d
    ret

net_fill_eth:
    mov rdi, NET_PKT_BUF_PHYS
    mov rsi, net_gateway_mac
    mov ecx, 6
    rep movsb
    mov rsi, e1000_mac
    mov ecx, 6
    rep movsb
    mov word [rdi], 0x0008
    ret

net_fill_ipv4:
    mov rsi, NET_PKT_BUF_PHYS + 14
    mov byte [rsi], 0x45
    mov byte [rsi + 1], 0
    mov ax, dx
    xchg al, ah
    mov word [rsi + 2], ax
    mov word [rsi + 4], 0x0040
    mov byte [rsi + 8], 64
    mov byte [rsi + 9], cl
    mov word [rsi + 10], 0
    mov eax, [net_ip_addr]
    mov [rsi + 12], eax
    mov eax, edi
    mov [rsi + 16], eax
    push rsi
    mov ecx, 10
    call net_ip_csum
    mov [rsi + 10], ax
    pop rsi
    ret

net_ip_csum:
    xor eax, eax
.sum:
    movzx edx, word [rsi]
    add eax, edx
    adc eax, 0
    add rsi, 2
    loop .sum
    not ax
    ret

net_tcp_csum:
    push rbx
    push r12
    push r13
    mov r12, rsi
    mov r13d, ecx
    xor eax, eax
    mov [r12 + 16], ax
    movzx ebx, word [NET_PKT_BUF_PHYS + 16]
    rol bx, 8
    add eax, ebx
    movzx ebx, word [NET_PKT_BUF_PHYS + 12]
    rol bx, 8
    add eax, ebx
    mov ebx, [NET_PKT_BUF_PHYS + 26]
    add eax, ebx
    adc eax, 0
    shr ebx, 16
    add eax, ebx
    adc eax, 0
    mov ebx, [NET_PKT_BUF_PHYS + 30]
    add eax, ebx
    adc eax, 0
    shr ebx, 16
    add eax, ebx
    adc eax, 0
    mov ebx, 0x0600
    add eax, ebx
    mov ebx, edx
    add eax, ebx
    adc eax, 0
    shr ebx, 16
    add eax, ebx
    adc eax, 0
    mov rsi, r12
    mov ecx, edx
    shr ecx, 1
.csum:
    test ecx, ecx
    jz .odd
    movzx ebx, word [rsi]
    add eax, ebx
    adc eax, 0
    add rsi, 2
    dec ecx
    jmp .csum
.odd:
    test edx, 1
    jz .fin
    movzx ebx, byte [rsi]
    shl ebx, 8
    add eax, ebx
    adc eax, 0
.fin:
    not ax
    pop r13
    pop r12
    pop rbx
    ret

net_ws_slot:
    mov byte [net_tcp_slot], 1
    mov word [net_tcp_local_port], 0xC001
    ret

net_http_slot:
    mov byte [net_tcp_slot], 0
    mov word [net_tcp_local_port], 0xC000
    ret

net_dns_resolve:
    push rbx
    mov rbx, rdi
    mov dword [net_dns_result], 0
    mov byte [net_dns_pending], 1
    call net_tx_dns
    mov ecx, 60000
.wait:
    call net_poll
    cmp byte [net_dns_pending], 0
    jne .again
    mov eax, [net_dns_result]
    jmp .out
.again:
    dec ecx
    jnz .wait
    xor eax, eax
.out:
    pop rbx
    ret

net_tx_dns:
    mov rdi, NET_PKT_BUF_PHYS + 34
    mov word [rdi], 0x0400
    mov word [rdi + 2], 0x3500
    mov word [rdi + 4], 0
    mov word [rdi + 6], 0
    add rdi, 8
    mov rsi, rbx
.encode:
    mov al, [rsi]
    test al, al
    jz .endname
    mov byte [rdi + 1], al
    mov byte [rdi], 1
    add rdi, 2
    inc rsi
    jmp .encode
.endname:
    mov byte [rdi], 0
    mov word [rdi + 1], 0x0100
    mov word [rdi + 3], 0x0100
    mov rdx, rdi
    sub rdx, NET_PKT_BUF_PHYS + 34
    add rdx, 5
    mov ax, dx
    add ax, 8
    xchg al, ah
    mov word [NET_PKT_BUF_PHYS + 38], ax
    call net_tx_udp
    ret

net_tcp_connect:
    mov [net_tcp_remote_ip], edi
    mov [net_tcp_remote_port], si
    mov dword [net_tcp_seq], 0x10000000
    mov dword [net_tcp_ack], 0
    mov byte [net_tcp_state], 1
    mov dword [net_tcp_rx_len], 0
    mov byte [net_http_done], 0
    mov byte [net_tcp_retx], 0
    mov eax, [pit_ticks]
    mov [net_tcp_syn_tick], eax
    call net_tx_tcp_syn
    mov ecx, 100000
.wait:
    call net_poll
    cmp byte [net_tcp_state], 2
    je .ok
    dec ecx
    jnz .wait
    cmp byte [net_tcp_retx], 5
    jae .fail
    inc byte [net_tcp_retx]
    mov eax, [pit_ticks]
    mov [net_tcp_syn_tick], eax
    call net_tx_tcp_syn
    mov ecx, 50000
    jmp .wait
.fail:
    xor eax, eax
    ret
.ok:
    mov eax, 1
    ret

net_tcp_check_retx:
    cmp byte [net_tcp_state], 1
    jne .out
    mov rax, [pit_ticks]
    sub rax, [net_tcp_syn_tick]
    cmp rax, 500
    jb .out
    cmp byte [net_tcp_retx], 5
    jae .out
    inc byte [net_tcp_retx]
    mov rax, [pit_ticks]
    mov [net_tcp_syn_tick], rax
    call net_tx_tcp_syn
.out:
    ret

net_http_get:
    push rbx
    mov rbx, rdi
    call net_http_slot
    call net_parse_url
    lea rdi, [net_host_buf]
    call net_dns_resolve
    test eax, eax
    jz .fail
    mov edi, eax
    mov esi, 0x5000
    call net_tcp_connect
    test rax, rax
    jz .fail
    call net_build_http
    lea rsi, [net_http_buf]
    mov edx, eax
    call net_tx_tcp_data
    mov ecx, 300000
.wait:
    call net_poll
    cmp byte [net_http_done], 1
    je .parse
    dec ecx
    jnz .wait
.fail:
    call net_set_error
    xor eax, eax
    jmp .out
.parse:
    call html_to_lines
    mov eax, 1
.out:
    pop rbx
    ret

net_https_probe:
    jmp net_https_get

net_https_get:
    push rbx
    mov rbx, rdi
    call net_http_slot
    call net_parse_url
    lea rdi, [net_host_buf]
    call net_dns_resolve
    test eax, eax
    jz .fail
    mov edi, eax
    mov esi, 0xBB01
    call net_tcp_connect
    test rax, rax
    jz .fail
    lea rdi, [net_host_buf]
    call tls_send_client_hello
    mov rsi, NET_PKT_BUF_PHYS + 512
    mov edx, eax
    call net_tx_tcp_data
    mov ecx, 300000
.wait:
    call net_poll
    cmp byte [net_http_done], 1
    je .tls_parse
    dec ecx
    jnz .wait
.fail:
    call net_set_error
    xor eax, eax
    jmp .out
.tls_parse:
    call tls_read_records
    test eax, eax
    jnz .html
    lea rsi, [msg_tls_hs]
    lea rdi, [net_fetch_title]
    call net_copy_str
    mov dword [net_fetch_count], 2
    lea rax, [net_fetch_lines]
    lea rdx, [msg_line1]
    mov [rax], rdx
    lea rdx, [msg_tls_hs]
    mov [rax + 8], rdx
    mov qword [rax + 16], 0
    mov eax, 1
    jmp .out
.html:
    call html_to_lines
    mov eax, 1
.out:
    pop rbx
    ret

net_parse_url:
    mov rdi, rbx
    lea rsi, [net_pfx_http]
    call net_has_prefix
    test rax, rax
    jnz .h8
    lea rsi, [net_pfx_https]
    call net_has_prefix
    test rax, rax
    jnz .h9
    ret
.h8:
    add rdi, 7
    jmp .host
.h9:
    add rdi, 8
.host:
    lea rsi, [net_host_buf]
.copy_h:
    mov al, [rdi]
    cmp al, '/'
    je .slash
    test al, al
    jz .slash
    mov [rsi], al
    inc rsi
    inc rdi
    jmp .copy_h
.slash:
    mov byte [rsi], 0
    lea rsi, [net_path_buf]
    cmp byte [rdi], 0
    je .root
    cmp byte [rdi], '/'
    jne .root
.copy_p:
    mov al, [rdi]
    test al, al
    jz .done
    mov [rsi], al
    inc rsi
    inc rdi
    jmp .copy_p
.root:
    mov byte [rsi], '/'
    inc rsi
    mov byte [rsi], 0
.done:
    ret

net_build_http:
    lea rdi, [net_http_buf]
    lea rsi, [txt_get]
    call net_copy_str
    mov rdi, rax
    lea rsi, [net_path_buf]
    call net_copy_str
    mov rdi, rax
    lea rsi, [txt_httpver]
    call net_copy_str
    mov rdi, rax
    lea rsi, [txt_host]
    call net_copy_str
    mov rdi, rax
    lea rsi, [net_host_buf]
    call net_copy_str
    mov rdi, rax
    lea rsi, [txt_crlf2]
    call net_copy_str
    sub rax, net_http_buf
    ret

net_split_body:
    lea rsi, [txt_remote]
    lea rdi, [net_fetch_title]
    call net_copy_str
    lea rbx, [NET_FETCH_BUF_PHYS]
    lea r8, [net_fetch_lines]
    xor ecx, ecx
    mov dword [net_fetch_count], 0
.split:
    cmp ecx, [net_tcp_rx_len]
    jae .end
    cmp dword [net_fetch_count], 20
    jae .end
    mov rax, rcx
    add rax, NET_FETCH_BUF_PHYS
    mov rdx, rcx
    mov [r8], rax
    inc dword [net_fetch_count]
    add r8, 8
.scan:
    cmp ecx, [net_tcp_rx_len]
    jae .end
    cmp byte [rbx + rcx], 0x0A
    je .nl
    inc ecx
    jmp .scan
.nl:
    mov byte [rbx + rcx], 0
    inc ecx
.end:
    mov eax, [net_fetch_count]
    mov qword [r8], 0
    ret

net_set_error:
    lea rsi, [txt_error]
    lea rdi, [net_fetch_title]
    call net_copy_str
    mov dword [net_fetch_count], 1
    lea rax, [net_fetch_lines]
    lea rdx, [txt_error]
    mov [rax], rdx
    mov qword [rax + 8], 0
    ret

net_copy_str:
.copy:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .done
    inc rsi
    inc rdi
    jmp .copy
.done:
    mov rax, rdi
    ret

net_has_prefix:
    push rdi
.loop:
    mov al, [rsi]
    test al, al
    jz .yes
    cmp al, [rdi]
    jne .no
    inc rsi
    inc rdi
    jmp .loop
.yes:
    mov rax, 1
    jmp .out
.no:
    xor rax, rax
.out:
    pop rdi
    ret

section .rodata
net_pfx_http:    db "http://", 0
net_pfx_https:   db "https://", 0
txt_get:     db "GET ", 0
txt_httpver: db " HTTP/1.1", 13, 10, 0
txt_host:    db "Host: ", 0
txt_crlf2:   db 13, 10, 13, 10, 0
txt_remote:  db "Remote", 0
txt_error:   db "Fetch failed", 0
msg_tls_hs: db "TLS handshake received from server.", 0
msg_line1:  db "DNS and TCP OK. TLS decrypt next.", 0
