; Navine OS - WebSocket client (RFC6455 text frames)

[BITS 64]

global ws_connect
global ws_send_text
global ws_poll
global ws_connected
global ws_rx_buf
global ws_feed

section .bss
ws_connected:   resb 1
ws_rx_buf:      resb 2048
ws_rx_len:      resd 1
ws_host:        resb 64
ws_path:        resb 128
ws_key:         resb 32

section .text
ws_connect:
    push rbx
    mov rbx, rdi
    lea rdi, [ws_host]
    lea rsi, [rbx]
    call ws_copy_str
    lea rdi, [ws_path]
    lea rsi, [rdx]
    call ws_copy_str
    mov byte [ws_connected], 0
    mov dword [ws_rx_len], 0
    call net_ws_slot
    lea rdi, [ws_host]
    call net_dns_resolve
    test eax, eax
    jz .fail
    mov edi, eax
    mov esi, 0xBB01
    call net_tcp_connect
    test rax, rax
    jz .fail
    call ws_build_upgrade
    lea rsi, [NET_PKT_BUF_PHYS + 512]
    mov edx, eax
    call net_tx_tcp_data
    mov ecx, 200000
.wait:
    call net_poll
    cmp byte [ws_connected], 1
    je .ok
    dec ecx
    jnz .wait
.fail:
    xor eax, eax
    jmp .out
.ok:
    mov eax, 1
.out:
    pop rbx
    ret

ws_build_upgrade:
    lea rdi, [NET_PKT_BUF_PHYS + 512]
    lea rsi, [ws_req1]
    call ws_append
    lea rsi, [ws_path]
    call ws_append
    lea rsi, [ws_req2]
    call ws_append
    lea rsi, [ws_host]
    call ws_append
    lea rsi, [ws_req3]
    call ws_append
    lea rsi, [ws_key_hdr]
    call ws_append
    lea rsi, [ws_key]
    call ws_append
    lea rsi, [ws_req_end]
    call ws_append
    mov rax, rdi
    sub rax, NET_PKT_BUF_PHYS + 512
    ret

ws_append:
.copy:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .done
    inc rsi
    inc rdi
    jmp .copy
.done:
    dec rdi
    ret

ws_send_text:
    cmp byte [ws_connected], 0
    je .fail
    lea rdi, [NET_PKT_BUF_PHYS + 512]
    mov byte [rdi], 0x81
    mov eax, esi
    cmp eax, 125
    ja .long
    mov byte [rdi + 1], al
    lea rdi, [rdi + 2]
    jmp .payload
.long:
    mov byte [rdi + 1], 126
    mov ax, si
    xchg al, ah
    mov [rdi + 2], ax
    lea rdi, [rdi + 4]
.payload:
    mov rsi, rdx
    mov ecx, esi
    rep movsb
    mov rax, rdi
    sub rax, NET_PKT_BUF_PHYS + 512
    mov edx, eax
    lea rsi, [NET_PKT_BUF_PHYS + 512]
    call net_tx_tcp_data
    mov eax, 1
    ret
.fail:
    xor eax, eax
    ret

ws_poll:
    mov eax, [ws_rx_len]
    ret

ws_feed:
    lea rdi, [ws_rx_buf]
    add rdi, [ws_rx_len]
    mov ecx, esi
    cmp ecx, 2048
    ja .cap
    rep movsb
    add [ws_rx_len], esi
    call ws_try_parse
    ret
.cap:
    mov ecx, 2048
    sub ecx, [ws_rx_len]
    rep movsb
    mov dword [ws_rx_len], 2048
    call ws_try_parse
    ret

ws_try_parse:
    cmp dword [ws_rx_len], 4
    jb .out
    lea rdi, [ws_rx_buf]
    cmp byte [rdi], 0x81
    je .text
    cmp byte [rdi], 0x88
    je .close
    cmp dword [ws_rx_len], 12
    jb .out
    cmp dword [rdi], 0x48545450
    jne .out
    mov byte [ws_connected], 1
    mov dword [ws_rx_len], 0
    jmp .out
.text:
    movzx eax, byte [rdi + 1]
    and eax, 0x7F
    add eax, 2
    cmp eax, [ws_rx_len]
    ja .out
    mov dword [ws_rx_len], 0
.close:
    mov byte [ws_connected], 0
.out:
    ret

ws_copy_str:
.copy:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .done
    inc rsi
    inc rdi
    jmp .copy
.done:
    ret

section .rodata
ws_req1:    db "GET ", 0
ws_req2:    db " HTTP/1.1", 13, 10, "Host: ", 0
ws_req3:    db 13, 10, "Upgrade: websocket", 13, 10, "Connection: Upgrade", 13, 10, 0
ws_key_hdr: db "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==", 13, 10, 13, 10, 0
ws_req_end: db 0
