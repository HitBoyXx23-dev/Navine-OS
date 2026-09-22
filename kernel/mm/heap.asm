; Navine OS - Kernel Heap (linked-list allocator)

[BITS 64]

%include "constants.inc"

global init_heap
global kmalloc
global kfree
global heap_free_bytes
global heap_brk_current

section .bss
heap_memory:    resb KERNEL_HEAP_SIZE
heap_initialized: resb 1
heap_brk_current: resq 1

section .data
heap_head:
    .size:  dq KERNEL_HEAP_SIZE - 16
    .free:  dq 1
    .next:  dq 0

section .text
init_heap:
    mov byte [heap_initialized], 1
    lea rax, [heap_memory]
    mov [heap_brk_current], rax
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

heap_free_bytes:
    mov rsi, heap_head
    xor rax, rax
.count:
    cmp qword [rsi + 8], 0
    je .out
    cmp qword [rsi + 8], 1
    jne .next
    add rax, [rsi]
.next:
    mov rsi, [rsi + 16]
    test rsi, rsi
    jnz .count
.out:
    ret

heap_brk:
    mov rax, [heap_brk_current]
    ret
