; Navine OS - DMG volume mount table

[BITS 64]

%include "constants.inc"

global dmg_volume_mount
global dmg_volume_count
global dmg_volume_name
global dmg_app_bundle_detect

section .bss
dmg_mount_count: resd 1
dmg_mount_table: resb 8 * 64

section .text
dmg_volume_mount:
    call dmg_detect_magic
    test rax, rax
    jz .fail
    mov eax, [dmg_mount_count]
    cmp eax, 8
    jae .fail
    imul rcx, rax, 64
    lea rdi, [dmg_mount_table + rcx]
    lea rsi, [label_mounted]
    mov ecx, 16
    rep movsb
    mov qword [rdi + 16], 0
    mov dword [rdi + 24], 1
    mov dword [rdi + 28], 0
    inc dword [dmg_mount_count]
    mov rax, 1
    ret
.fail:
    xor rax, rax
    ret

dmg_detect_magic:
    cmp dword [rdi], 0x6B6F6C79
    je .ok
    cmp dword [rdi], 0x2B736668
    je .ok
    xor rax, rax
    ret
.ok:
    mov rax, 1
    ret

dmg_volume_count:
    mov eax, [dmg_mount_count]
    ret

dmg_volume_name:
    mov ecx, edi
    cmp ecx, [dmg_mount_count]
    jae .empty
    imul rax, rcx, 64
    lea rax, [dmg_mount_table + rax]
    ret
.empty:
    lea rax, [label_none]
    ret

dmg_app_bundle_detect:
    cmp dword [rdi], '.app'
    je .ok
    cmp dword [rdi + 4], 'PPA.'
    je .ok
    xor rax, rax
    ret
.ok:
    mov rax, 1
    ret

section .rodata
label_mounted: db "NavineDMG", 0
label_none:    db "(none)", 0
