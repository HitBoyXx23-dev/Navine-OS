; Navine OS - Virtual Filesystem Layer

[BITS 64]

%include "constants.inc"

global init_vfs
global vfs_open
global vfs_read
global vfs_write
global vfs_close
global vfs_path_open

section .bss
vfs_mounts:     resb 4096
vfs_fd_table:   resb MAX_FDS * 16
vfs_next_fd:    resd 1

section .text
init_vfs:
    mov dword [vfs_next_fd], 3
    xor eax, eax
    mov rdi, vfs_fd_table
    mov ecx, MAX_FDS * 4
    rep stosd
    ret

vfs_open:
    jmp vfs_path_open

vfs_path_open:
    call filecache_resolve
    test rax, rax
    jz .fail
    mov r9, rax
    mov r10, rdx
    mov eax, [vfs_next_fd]
    cmp eax, MAX_FDS
    jae .fail
    mov ecx, eax
    imul rdi, rcx, 16
    lea rdi, [vfs_fd_table + rdi]
    mov [rdi], r9
    mov [rdi + 8], r10
    inc dword [vfs_next_fd]
    mov rax, rcx
    ret
.fail:
    xor rax, rax
    ret

vfs_read:
    push rbx
    push rsi
    mov r8d, esi
    cmp edi, 3
    jb .zero
    sub edi, 3
    cmp edi, MAX_FDS - 3
    jae .zero
    imul rax, rdi, 16
    lea rbx, [vfs_fd_table + rax]
    mov rsi, [rbx]
    test rsi, rsi
    jz .zero
    mov ecx, [rbx + 8]
    test ecx, ecx
    jz .zero
    test r8d, r8d
    jz .zero
    cmp r8d, ecx
    cmovb ecx, r8d
    mov rdi, rdx
    rep movsb
    mov rax, rcx
    jmp .out
.zero:
    xor rax, rax
.out:
    pop rsi
    pop rbx
    ret

vfs_write:
    mov r8, rdx
    mov edx, esi
    call navinefs_write
    ret

vfs_close:
    cmp edi, 3
    jb .ok
    sub edi, 3
    cmp edi, MAX_FDS - 3
    jae .ok
    imul rax, rdi, 16
    lea rdi, [vfs_fd_table + rax]
    mov qword [rdi], 0
    mov qword [rdi + 8], 0
.ok:
    ret
