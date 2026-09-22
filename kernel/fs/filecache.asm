; Navine OS - Path to content resolver (vault + NavineFS)

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern navinefs_lookup
extern navinefs_read
%endif

global filecache_resolve
global filecache_size

section .text
filecache_resolve:
    push rbx
    push r12
    mov r12, rdi
    lea rbx, [cache_table]
.loop:
    cmp qword [rbx], 0
    je .try_navine
    mov rdi, r12
    mov rsi, [rbx]
    call str_equal
    test rax, rax
    jnz .hit
    add rbx, 24
    jmp .loop
.hit:
    mov rax, [rbx + 8]
    mov rdx, [rbx + 16]
    jmp .done
.try_navine:
    mov rdi, r12
    call navinefs_lookup
    cmp eax, -1
    je .miss
    mov edi, eax
    mov r8, FILE_CACHE_PHYS
    mov edx, 4096
    call navinefs_read
    test rax, rax
    jz .miss
    mov rdx, rax
    mov rax, FILE_CACHE_PHYS
    jmp .done
.miss:
    xor rax, rax
    xor rdx, rdx
.done:
    pop r12
    pop rbx
    ret

filecache_size:
    call filecache_resolve
    ret

str_equal:
    push rsi
    push rdi
.cmp:
    movzx eax, byte [rdi]
    movzx ecx, byte [rsi]
    cmp al, cl
    jne .fail
    test al, al
    jz .ok
    inc rdi
    inc rsi
    jmp .cmp
.ok:
    mov rax, 1
    jmp .out
.fail:
    xor rax, rax
.out:
    pop rdi
    pop rsi
    ret

section .rodata
sample_exe_name: db "sample.exe", 0
sample_elf_name: db "sample.elf", 0
demo_dmg_name:   db "demo.dmg", 0
app_navapp_name: db "app.navapp", 0

cache_table:
    dq readme_name, content_readme, 128
    dq hello_name, content_hello, 64
    dq config_name, content_config, 96
    dq page_name, content_page, 80
    dq script_name, content_script, 48
    dq doom_wad_name, 0, 0
    dq theme_name, 0, 0
    dq plugin_name, content_plugin, 32
    dq sample_exe_name, sample_pe_blob, sample_pe_size
    dq sample_elf_name, sample_elf_blob, sample_elf_size
    dq demo_dmg_name, sample_dmg_blob, sample_dmg_size
    dq app_navapp_name, 0, 0
    dq 0

readme_name:  db "readme.txt", 0
hello_name:   db "hello.txt", 0
config_name:  db "config.json", 0
page_name:    db "page.html", 0
script_name:  db "script.sh", 0
doom_wad_name: db "doom1.wad", 0
theme_name:   db "default.navinetheme", 0
plugin_name:  db "sample.nplugin", 0

content_readme: db "Welcome to Navine OS Hybrid Edition.", 10, "Press Space for Spotlight.", 0
content_hello:  db "Navine OS - fast hybrid desktop.", 0
content_config: db "{", 34, "mode", 34, ":", 34, "hybrid", 34, "}", 0
content_page:   db "<html><body>Navine Portal</body></html>", 0
content_script: db "#!/bin/sh", 10, "echo Navine", 0
content_plugin: db "NPLUGINv1", 0

sample_pe_size: equ sample_pe_end - sample_pe_blob
sample_elf_size: equ sample_elf_end - sample_elf_blob
sample_dmg_size: equ sample_dmg_end - sample_dmg_blob

sample_pe_blob:
    db "MZ"
    times 58 db 0
    dd 128
    times 64 db 0
    db "PE", 0, 0
    dw 0x8664
    dw 1
    dd 0
    dd 0
    dw 0
    dw 0xF0
    dw 0x22B
    dw 0x14C
    dd 0x1000
    dd 0x200
    dw 0
    dw 0
    dd 0
    dd 0x3000
    dd 0x1000
    dd 0x100000
    dq 0x1000
    dd 0x1000
    dw 2
    dw 0
    dw 0
    dw 0
    dd 0
    dd 0x1000
    dd 0x200
    dw 0
    dw 0
    dq 0
    dq 0
    dq 0
    dq 0
    db ".text", 0, 0, 0
    dd 0x1000
    dd 0x200
    dd 0
    dd 0
    dd 0x60000000
    dd 0x20000000
sample_pe_end:

sample_elf_blob:
    db 0x7F, "ELF", 2, 1, 1, 0
    times 8 db 0
    dw 2
    dw 0x3E
    dd 1
    dq ELF_LOAD_PHYS + 0x1000
    dq 0x40
    dq 0
    dw 0x40
    dw 0x38
    dw 1
    dw 0
    dw 0
    dw 0
    dd 1
    dd 5
    dq 0x1000
    dq 0x1000
    dq 0x1000
    dq 0x1000
sample_elf_end:

sample_dmg_blob:
    db "koly"
    dd 0
    dd 0
    db "NavineDemo"
    times 64 db 0
sample_dmg_end:
