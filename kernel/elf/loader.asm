; Navine OS - ELF64 Executable Loader

[BITS 64]

%include "constants.inc"

global elf_load
global elf_run_user
global elf_map_segments

section .bss
elf_entry_point: resq 1
elf_mapped:      resb 1

section .text
elf_load:
    cmp dword [rdi], ELF_MAGIC
    jne .fail
    movzx eax, byte [rdi + 4]
    cmp al, ELFCLASS64
    jne .fail
    movzx eax, byte [rdi + 16]
    cmp al, ET_EXEC
    jne .fail
    mov rax, 1
    ret
.fail:
    xor rax, rax
    ret

elf_map_segments:
    mov byte [elf_mapped], 0
    call elf_load
    test rax, rax
    jz .fail
    mov r12, rdi
    movzx ecx, word [r12 + 0x38]
    movzx r8d, word [r12 + 0x36]
    lea r9, [r12 + 0x40]
    mov r10d, ecx
.ph:
    test r10d, r10d
    jz .done
    mov eax, [r9]
    cmp eax, PT_LOAD
    jne .next_ph
    mov rax, [r9 + 0x10]
    mov rbx, [r9 + 0x18]
    mov rcx, [r9 + 0x20]
    mov rdi, ELF_LOAD_PHYS
    add rdi, rax
    lea rsi, [r12 + rcx]
    mov rcx, [r9 + 0x28]
    cmp rcx, 4096
    jbe .copy
    mov rcx, 4096
.copy:
    test rcx, rcx
    jz .next_ph
    rep movsb
    mov rax, [r9 + 0x10]
    add rax, ELF_LOAD_PHYS
    mov [elf_entry_point], rax
.next_ph:
    add r9, r8
    dec r10d
    jmp .ph
.done:
    mov rax, [r12 + 0x18]
    mov [elf_entry_point], rax
    mov byte [elf_mapped], 1
    mov rax, 1
    ret
.fail:
    xor rax, rax
    ret

elf_exec:
    call elf_map_segments
    test rax, rax
    jz .fail
    mov rax, [elf_entry_point]
    test rax, rax
    jz .fail
    mov rax, 1
    ret
.fail:
    xor rax, rax
    ret

elf_run_user:
    call elf_map_segments
    test rax, rax
    jz .fail
    mov rax, [elf_entry_point]
    test rax, rax
    jz .fail
    mov rsp, PROC_USER_STACK_BASE + PROC_STACK_SIZE
    and rsp, 0xFFFFFFFFFFFFFFF0
    push 0x28
    push rsp
    pushfq
    push 0x28
    push rax
    iretq
.fail:
    xor rax, rax
    ret
