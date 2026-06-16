; Navine OS - Virtual Memory Manager (4-level paging)

[BITS 64]

%include "constants.inc"
%include "macros.inc"

%ifndef NAVINE_LINK_BUILD
extern pmm_alloc_page
%endif

global init_vmm
global vmm_map_page
global vmm_unmap_page

section .bss
kernel_pml4:    resb 4096

section .text
init_vmm:
    mov rax, cr3
    mov [kernel_pml4], rax
    ret

vmm_map_page:
    ; rdi=virt, rsi=phys, rdx=flags
    push rbp
    mov rbp, rsp
    mov r10, rdi
    shr r10, 39
    and r10, 0x1FF
    mov r11, rdi
    shr r11, 30
    and r11, 0x1FF
    mov r12, rdi
    shr r12, 21
    and r12, 0x1FF
    mov r13, rdi
    shr r13, 12
    and r13, 0x1FF
    mov rax, cr3
    mov r8, [rax + r10 * 8]
    test r8, PAGE_PRESENT
    jnz .has_pdpt
    call pmm_alloc_page
    test rax, rax
    jz .fail
    mov r8, rax
    or r8, PAGE_PRESENT | PAGE_WRITE
    mov rcx, cr3
    mov [rcx + r10 * 8], r8
.has_pdpt:
    and r8, 0xFFFFFFFFFFFFF000
    mov r9, [r8 + r11 * 8]
    test r9, PAGE_PRESENT
    jnz .has_pd
    call pmm_alloc_page
    test rax, rax
    jz .fail
    mov r9, rax
    or r9, PAGE_PRESENT | PAGE_WRITE
    mov [r8 + r11 * 8], r9
.has_pd:
    and r9, 0xFFFFFFFFFFFFF000
    mov r8, [r9 + r12 * 8]
    test r8, PAGE_PRESENT
    jnz .has_pt
    call pmm_alloc_page
    test rax, rax
    jz .fail
    mov r8, rax
    or r8, PAGE_PRESENT | PAGE_WRITE
    mov [r9 + r12 * 8], r8
.has_pt:
    and r8, 0xFFFFFFFFFFFFF000
    mov rax, rsi
    or rax, rdx
    or rax, PAGE_PRESENT
    mov [r8 + r13 * 8], rax
    mov rax, 1
    jmp .done
.fail:
    xor rax, rax
.done:
    mov rsp, rbp
    pop rbp
    ret

vmm_unmap_page:
    mov rax, rdi
    shr rax, 12
    mov rcx, cr3
    mov r8, rdi
    shr r8, 39
    and r8, 0x1FF
    mov r9, [rcx + r8 * 8]
    and r9, 0xFFFFFFFFFFFFF000
    mov r8, rdi
    shr r8, 30
    and r8, 0x1FF
    mov r10, [r9 + r8 * 8]
    and r10, 0xFFFFFFFFFFFFF000
    mov r8, rdi
    shr r8, 21
    and r8, 0x1FF
    mov r11, [r10 + r8 * 8]
    and r11, 0xFFFFFFFFFFFFF000
    mov r8, rdi
    shr r8, 12
    and r8, 0x1FF
    mov qword [r11 + r8 * 8], 0
    invlpg [rdi]
    ret
