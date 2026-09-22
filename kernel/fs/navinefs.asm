; Navine OS - NavineFS Journaling Filesystem

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern ata_read_sectors
extern ata_write_sectors
%endif

global init_navinefs
global navinefs_format
global navinefs_read
global navinefs_write
global navinefs_lookup
global navinefs_register
global navinefs_sync
global navinefs_mounted
global navinefs_normalize
global navinefs_list_entry

section .bss
navinefs_super:       resb 512
navinefs_mounted:     resb 1
navinefs_inodes:      resb NAVINEFS_MAX_INODES * 32
navinefs_journal:     resb NAVINEFS_JOURNAL_ENTRIES * 16
navinefs_jhead:       resd 1
navinefs_cache:       resb 4096
navinefs_cache_lba:   resd 1
navinefs_cache_dirty: resb 1
navinefs_path_buf:    resb 32

section .text
init_navinefs:
    mov rdi, NAVINEFS_DATA_LBA
    mov rsi, navinefs_super
    mov rdx, 1
    call ata_read_sectors
    cmp dword [navinefs_super], NAVINEFS_MAGIC
    jne .fresh
    mov rdi, NAVINEFS_INODE_LBA
    mov rsi, navinefs_inodes
    mov rdx, 4
    call ata_read_sectors
    mov rdi, NAVINEFS_JOURNAL_LBA
    mov rsi, navinefs_journal
    mov rdx, 2
    call ata_read_sectors
    mov byte [navinefs_mounted], 1
    ret
.fresh:
    mov byte [navinefs_mounted], 0
    mov dword [navinefs_jhead], 0
    mov byte [navinefs_cache_dirty], 0
    ret

navinefs_format:
    mov dword [navinefs_super], NAVINEFS_MAGIC
    mov dword [navinefs_super + 4], NAVINEFS_VERSION
    mov qword [navinefs_super + 8], NAVINEFS_DATA_LBA + 8
    mov qword [navinefs_super + 16], NAVINEFS_MAX_INODES
    mov dword [navinefs_super + 24], NAVINEFS_JOURNAL_LBA
    xor eax, eax
    mov rdi, navinefs_inodes
    mov ecx, NAVINEFS_MAX_INODES * 8
    rep stosd
    xor eax, eax
    mov rdi, navinefs_journal
    mov ecx, NAVINEFS_JOURNAL_ENTRIES * 4
    rep stosd
    mov dword [navinefs_jhead], 0
    mov byte [navinefs_cache_dirty], 0
    call navinefs_sync
    mov byte [navinefs_mounted], 1
    ret

navinefs_lookup:
    call navinefs_normalize
    mov rdi, rax
    xor eax, eax
    mov ecx, NAVINEFS_MAX_INODES
    lea r8, [navinefs_inodes]
.scan:
    cmp byte [r8], 0
    je .next
    push rdi
    push rsi
    lea rsi, [r8 + 1]
    call str_match
    pop rsi
    pop rdi
    test rax, rax
    jnz .found
.next:
    add r8, 32
    inc eax
    loop .scan
    mov rax, -1
    ret
.found:
    movzx eax, byte [r8 + 24]
    ret

navinefs_register:
    push rbx
    push r12
    push r13
    call navinefs_normalize
    mov r12, rax
    mov r13d, esi
    xor ebx, ebx
.find:
    cmp ebx, NAVINEFS_MAX_INODES
    jae .fail
    imul rax, rbx, 32
    lea rdi, [navinefs_inodes + rax]
    cmp byte [rdi], 0
    je .slot
    inc ebx
    jmp .find
.slot:
    mov byte [rdi], 1
    add rdi, 1
    mov rsi, r12
    call copy_name23
    imul rax, rbx, 32
    lea rdi, [navinefs_inodes + rax]
    mov [rdi + 24], r13b
    mov dword [rdi + 25], 0
    mov rax, 1
    jmp .out
.fail:
    xor rax, rax
.out:
    pop r13
    pop r12
    pop rbx
    ret

copy_name23:
    mov ecx, 23
.cl:
    test ecx, ecx
    jz .pad
    movzx eax, byte [rsi]
    mov [rdi], al
    test al, al
    jz .pad
    inc rsi
    inc rdi
    dec ecx
    jmp .cl
.pad:
    mov byte [rdi], 0
    ret

str_match:
    push rsi
    push rdi
.c:
    movzx eax, byte [rsi]
    movzx ecx, byte [rdi]
    cmp al, cl
    jne .fail
    test al, al
    jz .ok
    inc rsi
    inc rdi
    jmp .c
.ok:
    mov rax, 1
    jmp .out
.fail:
    xor rax, rax
.out:
    pop rdi
    pop rsi
    ret

navinefs_read:
    cmp byte [navinefs_mounted], 0
    je .zero
    cmp edx, 4096
    ja .zero
    mov eax, edi
    add eax, NAVINEFS_DATA_LBA + 8
    mov [navinefs_cache_lba], eax
    mov rdi, rax
    mov rsi, navinefs_cache
    mov rdx, 8
    call ata_read_sectors
    mov rcx, rdx
    cmp rcx, 4096
    ja .cap
    mov rsi, navinefs_cache
    mov rdi, r8
    rep movsb
    mov rax, rcx
    ret
.cap:
    mov rcx, 4096
    mov rsi, navinefs_cache
    mov rdi, r8
    rep movsb
    mov rax, 4096
    ret
.zero:
    xor rax, rax
    ret

navinefs_write:
    push rbx
    push rdx
    mov ebx, edi
    cmp byte [navinefs_mounted], 0
    je .fail
    mov eax, ebx
    add eax, NAVINEFS_DATA_LBA + 8
    mov [navinefs_cache_lba], eax
    pop rcx
    push rcx
    cmp rcx, 4096
    ja .cap
    mov rsi, r8
    mov rdi, navinefs_cache
    rep movsb
    mov byte [navinefs_cache_dirty], 1
    imul rax, rbx, 32
    lea rdi, [navinefs_inodes + rax]
    mov [rdi + 25], ecx
    mov edx, ecx
    call navinefs_journal_append
    mov rax, rcx
    pop rdx
    call navinefs_sync
    pop rbx
    ret
.cap:
    mov rcx, 4096
    mov rsi, r8
    mov rdi, navinefs_cache
    rep movsb
    mov byte [navinefs_cache_dirty], 1
    imul rax, rbx, 32
    lea rdi, [navinefs_inodes + rax]
    mov dword [rdi + 25], 4096
    mov edx, 4096
    call navinefs_journal_append
    mov rax, 4096
    pop rdx
    call navinefs_sync
    pop rbx
    ret
.fail:
    pop rdx
    pop rbx
    xor rax, rax
    ret

navinefs_journal_append:
    mov eax, [navinefs_jhead]
    imul rcx, rax, 16
    lea rdi, [navinefs_journal + rcx]
    mov eax, [navinefs_cache_lba]
    mov [rdi], eax
    mov eax, edx
    mov [rdi + 4], eax
    inc dword [navinefs_jhead]
    mov eax, [navinefs_jhead]
    cmp eax, NAVINEFS_JOURNAL_ENTRIES
    jb .out
    mov dword [navinefs_jhead], 0
.out:
    ret

navinefs_sync:
    cmp byte [navinefs_cache_dirty], 0
    je .super
    mov rdi, [navinefs_cache_lba]
    mov rsi, navinefs_cache
    mov rdx, 8
    call ata_write_sectors
    mov byte [navinefs_cache_dirty], 0
.super:
    cmp byte [navinefs_mounted], 0
    je .done
    mov rdi, NAVINEFS_DATA_LBA
    mov rsi, navinefs_super
    mov rdx, 1
    call ata_write_sectors
    mov rdi, NAVINEFS_INODE_LBA
    mov rsi, navinefs_inodes
    mov rdx, 4
    call ata_write_sectors
    mov rdi, NAVINEFS_JOURNAL_LBA
    mov rsi, navinefs_journal
    mov rdx, 2
    call ata_write_sectors
.done:
    ret

navinefs_normalize:
    lea rax, [navinefs_path_buf]
    test rdi, rdi
    jz .out
    cmp byte [rdi], '/'
    jne .copy
    inc rdi
.copy:
    push rdi
    mov rsi, rdi
    mov rdi, rax
    mov ecx, 31
.cl:
    test ecx, ecx
    jz .end
    movzx edx, byte [rsi]
    test dl, dl
    jz .end
    mov [rdi], dl
    inc rsi
    inc rdi
    dec ecx
    jmp .cl
.end:
    mov byte [rdi], 0
    pop rdi
.out:
    ret

navinefs_list_entry:
    cmp esi, NAVINEFS_MAX_INODES
    jae .empty
    imul rax, rsi, 32
    lea rdi, [navinefs_inodes + rax]
    cmp byte [rdi], 0
    je .empty
    lea rax, [rdi + 1]
    ret
.empty:
    xor rax, rax
    ret
