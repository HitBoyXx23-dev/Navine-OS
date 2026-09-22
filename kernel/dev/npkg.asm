; Navine OS - npkg package manager (kernel interface)

[BITS 64]

global npkg_init
global npkg_install
global npkg_remove
global npkg_list_count
global npkg_list_name

section .bss
npkg_pkg_count: resd 1

section .text
npkg_init:
    mov dword [npkg_pkg_count], 4
    ret

npkg_install:
    inc dword [npkg_pkg_count]
    mov rax, 1
    ret

npkg_remove:
    cmp dword [npkg_pkg_count], 0
    je .fail
    dec dword [npkg_pkg_count]
    mov rax, 1
    ret
.fail:
    xor rax, rax
    ret

npkg_list_count:
    mov eax, [npkg_pkg_count]
    ret

npkg_list_name:
    cmp edi, 0
    je .p0
    cmp edi, 1
    je .p1
    cmp edi, 2
    je .p2
    cmp edi, 3
    je .p3
    lea rax, [pkg_extra]
    ret
.p0:
    lea rax, [pkg_python]
    ret
.p1:
    lea rax, [pkg_node]
    ret
.p2:
    lea rax, [pkg_rust]
    ret
.p3:
    lea rax, [pkg_gcc]
    ret

section .rodata
pkg_python: db "python3", 0
pkg_node:   db "nodejs", 0
pkg_rust:   db "rust", 0
pkg_gcc:    db "gcc", 0
pkg_extra:  db "custom", 0
