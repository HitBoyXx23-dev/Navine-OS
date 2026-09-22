; Navine OS - PCI Enumeration

[BITS 64]

%include "constants.inc"
%include "macros.inc"

global init_pci
global pci_read_config
global pci_device_count
global pci_find_device
global pci_read_config
global pci_write_config
global pci_read_config_dev
global pci_write_config_dev
global pci_match_bus
global pci_match_dev
global pci_match_fn

section .bss
pci_devices:    resb 4096
pci_count:      resd 1
pci_match_bus:  resb 1
pci_match_dev:  resb 1
pci_match_fn:  resb 1

section .text
init_pci:
    xor eax, eax
    mov [pci_count], eax
    mov ebx, 0
.bus:
    mov ecx, 0
.dev:
    mov edx, 0
.func:
    mov eax, 0x80000000
    mov r8d, ebx
    shl r8d, 16
    or eax, r8d
    mov r9d, ecx
    shl r9d, 11
    or eax, r9d
    mov r9d, edx
    shl r9d, 8
    or eax, r9d
    mov dx, 0xCF8
    out dx, eax
    mov dx, 0xCFC
    in eax, dx
    cmp eax, 0xFFFFFFFF
    je .next_func
    cmp eax, 0
    je .next_func
    mov esi, pci_devices
    mov edi, [pci_count]
    imul edi, 16
    add esi, edi
    mov [esi], eax
    mov [esi + 4], ebx
    mov [esi + 8], ecx
    mov [esi + 12], edx
    inc dword [pci_count]
.next_func:
    inc edx
    cmp edx, 8
    jl .func
    inc ecx
    cmp ecx, 32
    jl .dev
    inc ebx
    cmp ebx, 8
    jl .bus
    ret

pci_read_config:
    mov eax, 0x80000000
    mov r8d, edi
    shl r8d, 16
    mov ax, si
    shl ax, 11
    or eax, r8d
    shl eax, 8
    or eax, edx
    mov dx, 0xCF8
    out dx, eax
    mov dx, 0xCFC
    in eax, dx
    ret

pci_device_count:
    mov eax, [pci_count]
    ret

pci_find_device:
    push rbx
    push r12
    mov r12d, edx
    xor ebx, ebx
.scan:
    mov eax, ebx
    cmp eax, [pci_count]
    jge .miss
    imul rax, 16
    lea rcx, [pci_devices + rax]
    mov eax, [rcx]
    shr eax, 16
    cmp ax, di
    jne .next
    mov eax, [rcx]
    and eax, 0xFFFF
    cmp ax, si
    jne .next
    mov al, [rcx + 4]
    mov [pci_match_bus], al
    mov al, [rcx + 8]
    mov [pci_match_dev], al
    mov al, [rcx + 12]
    mov [pci_match_fn], al
    mov rax, 1
    jmp .out
.next:
    inc ebx
    jmp .scan
.miss:
    xor rax, rax
.out:
    pop r12
    pop rbx
    ret

pci_write_config:
    mov eax, 0x80000000
    mov r8d, edi
    shl r8d, 16
    mov ax, si
    shl ax, 11
    or eax, r8d
    shl eax, 8
    or eax, edx
    mov dx, 0xCF8
    out dx, eax
    mov dx, 0xCFC
    mov eax, ebx
    out dx, eax
    ret

pci_read_config_dev:
    movzx edi, byte [pci_match_bus]
    movzx esi, byte [pci_match_dev]
    movzx ecx, byte [pci_match_fn]
    shl ecx, 8
    or edx, ecx
    call pci_read_config
    ret

pci_write_config_dev:
    movzx edi, byte [pci_match_bus]
    movzx esi, byte [pci_match_dev]
    movzx ecx, byte [pci_match_fn]
    shl ecx, 8
    or edx, ecx
    mov ebx, eax
    call pci_write_config
    ret
