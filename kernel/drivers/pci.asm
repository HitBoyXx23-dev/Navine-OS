; Navine OS - PCI Enumeration

[BITS 64]

%include "constants.inc"
%include "macros.inc"

global init_pci
global pci_read_config
global pci_device_count

section .bss
pci_devices:    resb 4096
pci_count:      resd 1

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
    mov eax, ebx
    shl eax, 16
    mov ax, cx
    shl ax, 11
    or eax, edx
    shl eax, 8
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
