; Navine OS - HTTP/HTML helpers

[BITS 64]

%include "constants.inc"

global html_skip_headers
global html_to_lines

section .text
html_skip_headers:
    lea rsi, [NET_FETCH_BUF_PHYS]
    mov ecx, [net_tcp_rx_len]
    xor eax, eax
.search:
    cmp eax, ecx
    jae .fail
    cmp byte [rsi + rax], 0x0D
    jne .next
    cmp byte [rsi + rax + 1], 0x0A
    jne .next
    cmp byte [rsi + rax + 2], 0x0D
    jne .next
    cmp byte [rsi + rax + 3], 0x0A
    jne .next
    add eax, 4
    jmp .found
.next:
    inc eax
    jmp .search
.fail:
    xor eax, eax
.found:
    push rax
    lea rdi, [cl_hdr]
    lea rsi, [NET_FETCH_BUF_PHYS]
    mov ecx, [net_tcp_rx_len]
    call html_find_cl
    pop rax
    test ebx, ebx
    jz .out
    add eax, ebx
    sub eax, [net_tcp_rx_len]
    jns .out
    neg eax
    add eax, ebx
.out:
    ret

html_find_cl:
    xor ebx, ebx
.scan:
    cmp ecx, 16
    jb .done
    lea rax, [rsi]
    lea rdi, [cl_hdr]
.match:
    mov al, [rdi]
    test al, al
    jz .parse
    cmp al, [rsi]
    jne .step
    inc rdi
    inc rsi
    dec ecx
    jmp .match
.parse:
    xor eax, eax
.digits:
    movzx edx, byte [rsi]
    cmp dl, '0'
    jb .done
    cmp dl, '9'
    ja .done
    imul eax, 10
    sub dl, '0'
    add eax, edx
    inc rsi
    dec ecx
    jmp .digits
.step:
    inc rsi
    dec ecx
    jmp .scan
.done:
    mov ebx, eax
    ret

section .rodata
cl_hdr: db "Content-Length:", 0

section .text
html_to_lines:
    call html_skip_headers
    mov ebx, eax
    add ebx, NET_FETCH_BUF_PHYS
    lea r8, [net_fetch_lines]
    mov dword [net_fetch_count], 0
    mov rcx, rbx
.strip:
    mov al, [rcx]
    test al, al
    jz .end
    cmp al, '<'
    jne .keep
.skip_tag:
    inc rcx
    mov al, [rcx]
    test al, al
    jz .end
    cmp al, '>'
    jne .skip_tag
    inc rcx
    jmp .strip
.keep:
    cmp dword [net_fetch_count], 20
    jae .end
    mov [r8], rcx
    add r8, 8
    inc dword [net_fetch_count]
.seek_nl:
    mov al, [rcx]
    test al, al
    jz .end
    cmp al, 0x0A
    je .nl
    cmp al, 0x0D
    je .nl
    cmp al, '<'
    je .strip
    inc rcx
    jmp .seek_nl
.nl:
    mov byte [rcx], 0
    inc rcx
    jmp .strip
.end:
    mov eax, [net_fetch_count]
    mov qword [r8], 0
    ret
