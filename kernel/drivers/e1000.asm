; Navine OS - Intel e1000 (82540EM) driver for VirtualBox NAT

[BITS 64]

%include "constants.inc"

global init_e1000
global e1000_send
global e1000_recv
global e1000_link_up
global e1000_mac

extern pci_find_device
extern pci_read_config
extern pci_write_config

section .bss
e1000_mmio:     resq 1
e1000_ready:    resb 1
e1000_rx_idx:   resd 1
e1000_tx_idx:   resd 1
e1000_mac:      resb 6

section .text
init_e1000:
    mov byte [e1000_ready], 0
    mov edi, 0x8086
    mov esi, 0x100E
    xor edx, edx
    call pci_find_device
    test rax, rax
    jz .fail
    call e1000_enable_pci
    call e1000_map_bar0
    test rax, rax
    jz .fail
    mov [e1000_mmio], rax
    call e1000_hw_reset
    call e1000_read_mac
    call e1000_init_rings
    mov byte [e1000_ready], 1
    mov eax, 1
    ret
.fail:
    xor eax, eax
    ret

e1000_enable_pci:
    mov edx, 0x04
    call pci_read_config_dev
    or eax, 0x06
    mov ebx, eax
    mov edx, 0x04
    mov eax, ebx
    call pci_write_config_dev
    ret

e1000_map_bar0:
    mov edx, 0x10
    call pci_read_config_dev
    and eax, 0xFFFFFFF0
    test eax, eax
    jnz .ok
    xor rax, rax
.ok:
    ret

e1000_hw_reset:
    mov edi, 0x0000
    call e1000_read32
    or eax, 0x04000000
    mov esi, eax
    call e1000_write32
.wait:
    mov edi, 0x0000
    call e1000_read32
    test eax, 0x04000000
    jnz .wait
    ret

e1000_read_mac:
    mov edi, 0x5400
    call e1000_read32
    mov [e1000_mac], al
    mov [e1000_mac + 1], ah
    shr eax, 16
    mov [e1000_mac + 2], al
    mov [e1000_mac + 3], ah
    mov edi, 0x5404
    call e1000_read32
    mov [e1000_mac + 4], al
    mov [e1000_mac + 5], ah
    ret

e1000_init_rings:
    xor eax, eax
    mov [e1000_rx_idx], eax
    mov [e1000_tx_idx], eax
    mov ecx, NET_DESC_COUNT
    xor ebx, ebx
.rx_desc:
    mov eax, NET_RX_BUF_PHYS
    imul r8d, ebx, NET_RX_BUF_SIZE
    add rax, r8
    mov rdi, NET_RX_DESC_PHYS
    imul r9, rbx, 16
    add rdi, r9
    mov [rdi], rax
    mov word [rdi + 8], 0
    mov byte [rdi + 10], 0
    inc ebx
    loop .rx_desc
    mov edi, 0x2800
    mov esi, NET_RX_DESC_PHYS
    call e1000_write32
    mov edi, 0x2804
    xor esi, esi
    call e1000_write32
    mov edi, 0x2808
    mov esi, NET_DESC_COUNT * 16
    call e1000_write32
    mov edi, 0x2810
    xor esi, esi
    call e1000_write32
    mov edi, 0x2818
    mov esi, NET_DESC_COUNT - 1
    call e1000_write32
    mov edi, 0x0100
    mov esi, 0x04008002
    call e1000_write32
    xor ebx, ebx
    mov ecx, NET_DESC_COUNT
.tx_desc:
    mov rdi, NET_TX_DESC_PHYS
    imul rax, rbx, 16
    add rdi, rax
    mov qword [rdi], 0
    mov word [rdi + 8], 0
    inc ebx
    loop .tx_desc
    mov edi, 0x3800
    mov esi, NET_TX_DESC_PHYS
    call e1000_write32
    mov edi, 0x3804
    xor esi, esi
    call e1000_write32
    mov edi, 0x3808
    mov esi, NET_DESC_COUNT * 16
    call e1000_write32
    mov edi, 0x3810
    xor esi, esi
    call e1000_write32
    mov edi, 0x3818
    xor esi, esi
    call e1000_write32
    mov edi, 0x0380
    mov esi, 0x0000010A
    call e1000_write32
    mov edi, 0x0410
    mov esi, 0x0060200A
    call e1000_write32
    ret

e1000_link_up:
    movzx rax, byte [e1000_ready]
    ret

e1000_send:
    cmp byte [e1000_ready], 0
    je .fail
    mov r12, rsi
    mov r13d, edx
    mov edi, 0x3818
    call e1000_read32
    mov r14d, eax
    mov eax, NET_TX_BUF_PHYS
    imul r8d, r14d, NET_RX_BUF_SIZE
    add rax, r8
    mov rdi, rax
    mov rsi, r12
    mov ecx, r13d
    rep movsb
    mov rdi, NET_TX_DESC_PHYS
    imul rax, r14, 16
    add rdi, rax
    mov rax, NET_TX_BUF_PHYS
    imul r8, r14, NET_RX_BUF_SIZE
    add rax, r8
    mov [rdi], rax
    mov ax, r13w
    mov [rdi + 8], ax
    mov byte [rdi + 11], 0x0B
    mov edi, 0x3818
    mov eax, r14d
    inc eax
    and eax, NET_DESC_COUNT - 1
    mov esi, eax
    call e1000_write32
    mov rdi, NET_TX_DESC_PHYS
    imul rax, r14, 16
    add rdi, rax
    mov ecx, 100000
.wait:
    movzx eax, byte [rdi + 12]
    test al, al
    jnz .ok
    dec ecx
    jnz .wait
.ok:
    mov rax, r12
    ret
.fail:
    xor rax, rax
    ret

e1000_recv:
    cmp byte [e1000_ready], 0
    je .zero
    mov ebx, [e1000_rx_idx]
    mov rdi, NET_RX_DESC_PHYS
    imul rax, rbx, 16
    add rdi, rax
    movzx eax, byte [rdi + 10]
    test al, 1
    jz .zero
    movzx edx, word [rdi + 8]
    cmp dx, 1536
    ja .zero
    mov rsi, [rdi]
    mov rdi, NET_PKT_BUF_PHYS
    push rsi
    push rdx
    mov rcx, rdx
    rep movsb
    pop rdx
    pop rsi
    mov byte [rsi + 10], 0
    mov qword [rsi], 0
    mov word [rsi + 8], 0
    mov edi, 0x2818
    mov esi, ebx
    call e1000_write32
    inc ebx
    and ebx, NET_DESC_COUNT - 1
    mov [e1000_rx_idx], ebx
    mov rax, NET_PKT_BUF_PHYS
    ret
.zero:
    xor rax, rax
    ret

e1000_read32:
    mov rax, [e1000_mmio]
    add rax, rdi
    mov eax, [rax]
    ret

e1000_write32:
    mov rax, [e1000_mmio]
    add rax, rdi
    mov [rax], esi
    ret
