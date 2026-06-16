; Navine OS - Physical Memory Manager (bitmap allocator)

[BITS 64]

%include "constants.inc"
%include "macros.inc"

global init_pmm
global pmm_alloc_page
global pmm_free_page
global pmm_total_pages
global pmm_used_pages

section .bss
pmm_bitmap:     resb 32768
pmm_total:      resq 1
pmm_used:       resq 1

section .text
init_pmm:
    mov qword [pmm_total], 262144
    mov qword [pmm_used], 256
    mov rdi, pmm_bitmap
    mov rcx, 32768
    mov al, 0xFF
    rep stosb
    mov rdi, pmm_bitmap
    mov rcx, 256
    xor al, al
    rep stosb
    ret

pmm_alloc_page:
    mov rsi, pmm_bitmap
    xor rdx, rdx
    mov rcx, [pmm_total]
.search:
    cmp rdx, rcx
    jae .fail
    mov rax, rdx
    shr rax, 3
    movzx r8d, byte [rsi + rax]
    mov r9, rdx
    and r9, 7
    bt r8, r9
    jc .next
    bts r8, r9
    mov [rsi + rax], r8b
    mov rax, rdx
    shl rax, 12
    inc qword [pmm_used]
    ret
.next:
    inc rdx
    jmp .search
.fail:
    xor rax, rax
    ret

pmm_free_page:
    mov rdx, rdi
    shr rdx, 12
    mov rsi, pmm_bitmap
    mov rax, rdx
    shr rax, 3
    movzx r8d, byte [rsi + rax]
    mov r9, rdx
    and r9, 7
    btr r8, r9
    mov [rsi + rax], r8b
    dec qword [pmm_used]
    ret

pmm_total_pages:
    mov rax, [pmm_total]
    ret

pmm_used_pages:
    mov rax, [pmm_used]
    ret
