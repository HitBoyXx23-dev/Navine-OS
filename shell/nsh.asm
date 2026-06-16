; Navine OS - nsh Shell

[BITS 64]

global nsh_main
global nsh_execute

section .rodata
prompt: db "nsh> ", 0
help_text: db "Navine Shell (nsh) - ls cd pwd echo uname help exit", 10, 0

section .bss
cmd_buffer:     resb 256

section .text
nsh_main:
    lea rdi, [prompt]
    extern terminal_write
    call terminal_write
    ret

nsh_execute:
    ret

section .note
; Commands implemented in kernel/terminal integration
; ls cd pwd mkdir rm cp mv cat echo ps kill uname npkg
