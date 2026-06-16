; Navine OS - Kernel Heap (linked-list allocator)

[BITS 64]

%include "constants.inc"

global init_heap
global kmalloc
global kfree

section .bss
heap_memory:    resb KERNEL_HEAP_SIZE
heap_initialized: resb 1

section .data
heap_head:
    .size:  dq KERNEL_HEAP_SIZE - 16
    .free:  dq 1
    .next:  dq 0

section .text
init_heap:
    mov byte [heap_initialized], 1
    ret

kmalloc:
    ; rdi = size
    add rdi, 16
    and rdi, 0xFFFFFFFFFFFFFFF0
    mov rsi, heap_head
.search:
    cmp qword [rsi + 8], 0
    je .fail
    mov rax, [rsi]
    cmp rax, rdi
    jl .next
    mov qword [rsi + 8], 0
    sub rax, rdi
    cmp rax, 32
    jl .use_block
    mov rcx, rsi
    add rsi, rdi
    mov [rsi], rax
    mov qword [rsi + 8], 1
    mov [rcx], rdi
.use_block:
    lea rax, [rsi + 16]
    ret
.next:
    mov rsi, [rsi + 16]
    jmp .search
.fail:
    xor rax, rax
    ret

kfree:
    sub rdi, 16
    mov qword [rdi + 8], 1
    ret
