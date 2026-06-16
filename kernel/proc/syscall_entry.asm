; kernel/proc/syscall_entry.asm
; Language: NASM x86-64
; Purpose: System V compatible syscall entry trampoline.

[BITS 64]
global syscall_entry
extern syscall_dispatch

section .text
syscall_entry:
    push rcx
    push r11
    push rdi
    push rsi
    push rdx
    push r10
    push r8
    push r9
    mov rcx, r10
    mov rdi, rax
    call syscall_dispatch
    pop r9
    pop r8
    pop r10
    pop rdx
    pop rsi
    pop rdi
    pop r11
    pop rcx
    o64 sysret
