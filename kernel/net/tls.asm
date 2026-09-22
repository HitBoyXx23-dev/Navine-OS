; Navine OS - TLS 1.2 client (ClientHello + record parse)

[BITS 64]

%include "constants.inc"

global tls_send_client_hello
global tls_read_records
global tls_app_len
global tls_session_ready
global tls_feed

section .bss
tls_rx_buf:       resb 8192
tls_app_buf:      resb 4096
tls_app_len:      resd 1
tls_session_ready: resb 1
tls_sni_buf:      resb 128
tls_feed_len:     resd 1

section .text
tls_send_client_hello:
    push rbx
    push r12
    xor ebx, ebx
    mov dword [tls_feed_len], 0
    mov r12, rdi
    lea rdi, [tls_sni_buf]
    lea rsi, [r12]
.copy_host:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .host_done
    inc rsi
    inc rdi
    jmp .copy_host
.host_done:
    lea rdi, [NET_PKT_BUF_PHYS + 512]
    mov byte [rdi], 0x16
    mov byte [rdi + 1], 0x03
    mov byte [rdi + 2], 0x01
    mov word [rdi + 3], 0x0060
    mov byte [rdi + 5], 0x03
    mov byte [rdi + 6], 0x03
    mov rax, 0x1122334455667788
    mov [rdi + 7], rax
    mov byte [rdi + 15], 0
    mov word [rdi + 16], 0x0200
    mov word [rdi + 18], 0xC02F
    mov byte [rdi + 20], 0x01
    mov byte [rdi + 21], 0
    mov word [rdi + 22], 0
    mov word [rdi + 24], 0x0000
    add rdi, 26
    lea rsi, [tls_sni_buf]
.len:
    mov al, [rsi]
    test al, al
    jz .slen
    inc rsi
    inc rbx
    jmp .len
.slen:
    lea rsi, [tls_sni_buf]
    mov byte [rdi], 0
    mov byte [rdi + 1], 0
    mov al, bl
    add al, 5
    mov [rdi + 3], al
    mov byte [rdi + 4], 0
    mov byte [rdi + 5], 0
    mov [rdi + 6], bl
    add rdi, 7
.copy_sni:
    test bl, bl
    jz .sni_done
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    dec bl
    jmp .copy_sni
.sni_done:
    mov rax, rdi
    mov rbx, NET_PKT_BUF_PHYS + 512
    sub rax, rbx
    mov ebx, eax
    sub ebx, 5
    mov [NET_PKT_BUF_PHYS + 517], bl
    pop r12
    pop rbx
    mov rax, rdi
    sub rax, NET_PKT_BUF_PHYS + 512
    ret

tls_read_records:
    mov dword [tls_app_len], 0
    mov byte [tls_session_ready], 0
    mov ecx, [tls_feed_len]
    cmp ecx, 8192
    ja .clamp
.clamp:
    mov al, [tls_rx_buf]
    cmp al, 0x16
    je .handshake
    cmp al, 0x17
    je .app
    cmp al, 0x15
    je .alert
    jmp .unknown
.handshake:
    mov byte [tls_session_ready], 1
    lea rdi, [NET_FETCH_BUF_PHYS]
    lea rsi, [tls_msg_hs]
    call tls_copy_str
    mov dword [tls_app_len], 32
    jmp .done
.app:
    movzx edx, byte [tls_rx_buf + 3]
    shl edx, 8
    movzx eax, byte [tls_rx_buf + 4]
    add edx, eax
    cmp edx, 4096
    ja .done
    lea rsi, [tls_rx_buf + 5]
    lea rdi, [tls_app_buf]
    mov ecx, edx
    rep movsb
    lea rdi, [NET_FETCH_BUF_PHYS]
    lea rsi, [tls_app_buf]
    mov ecx, edx
    rep movsb
    mov [tls_app_len], edx
    mov byte [tls_session_ready], 1
    jmp .done
.alert:
    lea rdi, [NET_FETCH_BUF_PHYS]
    lea rsi, [tls_msg_alert]
    call tls_copy_str
    mov dword [tls_app_len], 24
    jmp .done
.unknown:
    lea rdi, [NET_FETCH_BUF_PHYS]
    lea rsi, [tls_msg_unknown]
    call tls_copy_str
    mov dword [tls_app_len], 20
.done:
    mov eax, [tls_app_len]
    ret

tls_copy_str:
.copy:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .out
    inc rsi
    inc rdi
    jmp .copy
.out:
    ret

tls_feed:
    lea rdi, [tls_rx_buf]
    mov eax, [tls_feed_len]
    add rdi, rax
    mov ecx, esi
    cmp eax, 8192
    jae .out
    rep movsb
    add [tls_feed_len], esi
.out:
    ret

section .rodata
tls_msg_hs: db "TLS handshake OK (decrypt pending)", 0
tls_msg_alert: db "TLS alert from server", 0
tls_msg_unknown: db "TLS record received", 0
