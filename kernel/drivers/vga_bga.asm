; Navine OS - Bochs/VirtualBox BGA graphics (PCI BAR + DISPI ports)

[BITS 64]

%include "constants.inc"
%include "macros.inc"

global vga_probe_framebuffer

section .text
vga_probe_framebuffer:
    mov rax, FB_INFO_PHYS
    cmp dword [rax + FB_INFO_BPP_OFF], 8
    je .out
    call vga_find_pci_bar
    test rax, rax
    jz .out
    mov rcx, FB_INFO_PHYS
    mov [rcx], rax
.out:
    ret

vga_find_pci_bar:
    xor r12d, r12d
.bus:
    cmp r12d, 8
    jae .miss
    xor r13d, r13d
.dev:
    cmp r13d, 32
    jae .next_bus
    xor r14d, r14d
.func:
    cmp r14d, 8
    jae .next_dev
    mov edi, r12d
    mov esi, r13d
    mov edx, r14d
    xor ecx, ecx
    call pci_cfg_read32
    cmp eax, 0xFFFFFFFF
    je .next_func
    cmp eax, 0
    je .next_func
    mov r15d, eax
    cmp r15w, 0x1111
    jne .vbox
    shr r15d, 16
    cmp r15w, 0x1234
    je .bar
.vbox:
    mov r15d, eax
    cmp r15w, 0xBEEF
    jne .klass
    shr r15d, 16
    cmp r15w, 0x80EE
    je .bar
.klass:
    mov edi, r12d
    mov esi, r13d
    mov edx, r14d
    mov ecx, 8
    call pci_cfg_read32
    shr eax, 8
    and eax, 0xFFFF
    cmp ax, 0x0300
    jne .next_func
.bar:
    mov r15d, 0x10
.bar_try:
    mov edi, r12d
    mov esi, r13d
    mov edx, r14d
    mov ecx, r15d
    call pci_cfg_read32
    test al, 1
    jnz .bar_next
    and eax, 0xFFFFFFF0
    test rax, rax
    jz .bar_next
    ret
.bar_next:
    add r15d, 4
    cmp r15d, 0x20
    jbe .bar_try
    jmp .next_func
.next_func:
    inc r14d
    jmp .func
.next_dev:
    inc r13d
    jmp .dev
.next_bus:
    inc r12d
    jmp .bus
.miss:
    xor rax, rax
    ret

pci_cfg_read32:
    mov r8d, edi
    shl r8d, 16
    mov r9d, esi
    shl r9d, 11
    or r8d, r9d
    mov r9d, edx
    shl r9d, 8
    or r8d, r9d
    or r8d, ecx
    or r8d, 0x80000000
    mov dx, 0xCF8
    mov eax, r8d
    out dx, eax
    mov dx, 0xCFC
    in eax, dx
    ret

vga_bga_enable_mode:
    mov dx, 0x1CE
    xor ax, ax
    out dx, ax
    mov dx, 0x1CF
    in ax, dx
    sub ax, 0xB0C0
    cmp ax, 6
    jae .out
    mov dx, 0x1CE
    mov ax, 4
    out dx, ax
    mov dx, 0x1CF
    xor ax, ax
    out dx, ax
    mov dx, 0x1CE
    mov ax, 1
    out dx, ax
    mov dx, 0x1CF
    mov ax, VESA_WIDTH
    out dx, ax
    mov dx, 0x1CE
    mov ax, 2
    out dx, ax
    mov dx, 0x1CF
    mov ax, VESA_HEIGHT
    out dx, ax
    mov dx, 0x1CE
    mov ax, 3
    out dx, ax
    mov dx, 0x1CF
    mov ax, VESA_BPP
    out dx, ax
    mov dx, 0x1CE
    mov ax, 6
    out dx, ax
    mov dx, 0x1CF
    mov ax, VESA_WIDTH
    out dx, ax
    mov dx, 0x1CE
    mov ax, 4
    out dx, ax
    mov dx, 0x1CF
    mov ax, 0x41
    out dx, ax
.out:
    ret
