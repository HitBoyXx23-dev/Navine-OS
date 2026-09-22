; Navine OS - PE32+ loader (WineNavine kernel path)

[BITS 64]

%include "constants.inc"

global pe_loader_map
global pe_loader_exec
global pe_loader_entry

section .bss
pe_entry_rva:   resd 1
pe_image_base:  resd 1
pe_mapped:      resb 1

section .text
pe_loader_map:
    mov byte [pe_mapped], 0
    call pe_detect_header
    test rax, rax
    jz .fail
    mov r12, rdi
    mov eax, [r12 + 0x3C]
    add rax, r12
    mov r13, rax
    cmp dword [r13], 0x00004550
    jne .fail
    movzx eax, word [r13 + 0x18]
    cmp ax, 0x20B
    jne .fail
    mov eax, [r13 + 0x28]
    mov [pe_entry_rva], eax
    mov eax, [r13 + 0x30]
    mov [pe_image_base], eax
    movzx ecx, word [r13 + 6]
    movzx r8d, word [r13 + 0x14]
    lea r14, [r13 + 0x18]
    add r14, r8
    mov r15d, ecx
.sec:
    test r15d, r15d
    jz .mapped
    mov eax, [r14 + 0x0C]
    mov ebx, [r14 + 0x10]
    mov ecx, [r14 + 0x14]
    cmp ebx, 0
    je .next_sec
    mov rdi, PE_LOAD_PHYS
    add rdi, rax
    lea rsi, [r12 + rcx]
    mov rcx, rbx
    cmp rcx, 4096
    jbe .copy_ok
    mov rcx, 4096
.copy_ok:
    rep movsb
.next_sec:
    add r14, 40
    dec r15d
    jmp .sec
.mapped:
    mov byte [pe_mapped], 1
    mov rax, 1
    ret
.fail:
    xor rax, rax
    ret

pe_detect_header:
    cmp word [rdi], 0x5A4D
    jne .no
    mov eax, 1
    ret
.no:
    xor rax, rax
    ret

pe_loader_entry:
    mov eax, [pe_entry_rva]
    mov rbx, PE_LOAD_PHYS
    add rax, rbx
    ret

pe_loader_exec:
    cmp byte [pe_mapped], 0
    je .fail
    call pe_loader_entry
    test rax, rax
    jz .fail
    call rax
    mov rax, 1
    ret
.fail:
    xor rax, rax
    ret
