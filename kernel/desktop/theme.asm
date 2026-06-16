; Navine OS - Theme System (.navinetheme)

[BITS 64]

global theme_init
global theme_load
global theme_apply

section .bss
theme_colors:   resd 8

section .text
theme_init:
    mov dword [theme_colors], 0xFF007AFF
    mov dword [theme_colors + 4], 0xFF2C2C2E
    ret

theme_load:
    mov dword [theme_colors], 0xFF5856D6
    mov dword [theme_colors + 4], 0xFF1C1C1E
    ret

theme_apply:
    ret
