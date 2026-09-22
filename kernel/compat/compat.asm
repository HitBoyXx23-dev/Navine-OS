; Navine OS - Compatibility Layer (PE / ELF / DMG profiles)

[BITS 64]

%include "constants.inc"

global compat_init
global compat_pe_load
global pe_detect
global elf_detect
global compat_elf_load
global compat_dmg_mount
global dmg_detect
global compat_set_profile
global compat_get_profile

section .bss
compat_profile: resb 1

section .text
compat_init:
    mov byte [compat_profile], INSTALL_MODE_HYBRID
    call linux_syscall_init
    ret

compat_set_profile:
    mov [compat_profile], al
    ret

compat_get_profile:
    movzx rax, byte [compat_profile]
    ret

compat_load_path:
    call filecache_resolve
    test rax, rax
    ret

pe_detect:
    test rdi, rdi
    jz .no
    cmp word [rdi], 0x5A4D
    jne .no
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

compat_pe_load:
    call compat_load_path
    test rax, rax
    jz .fail
    mov rbx, rax
    mov rdi, rbx
    call pe_detect
    test rax, rax
    jz .fail
    mov rdi, rbx
    call pe_loader_map
    ret
.fail:
    xor rax, rax
    ret

elf_detect:
    test rdi, rdi
    jz .no
    cmp dword [rdi], ELF_MAGIC
    jne .no
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

compat_elf_load:
    call compat_load_path
    test rax, rax
    jz .fail
    mov rbx, rax
    mov rdi, rbx
    call elf_detect
    test rax, rax
    jz .fail
    mov rdi, rbx
    call elf_map_segments
    test rax, rax
    jz .fail
    call linux_syscall_enable
    ret
.fail:
    xor rax, rax
    ret

dmg_detect:
    test rdi, rdi
    jz .no
    cmp dword [rdi], 0x6B6F6C79
    je .yes
    cmp dword [rdi], 0x2B736668
    je .yes
    xor rax, rax
    ret
.yes:
    mov rax, 1
    ret
.no:
    xor rax, rax
    ret

compat_dmg_mount:
    call compat_load_path
    test rax, rax
    jz .fail
    mov rdi, rax
    call dmg_volume_mount
    ret
.fail:
    xor rax, rax
    ret
