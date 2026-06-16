; Navine OS - C++ Native App Launcher

[BITS 64]

%include "constants.inc"

extern ata_read_sectors

global cppapp_launch
global init_cppapp

section .bss
cppapp_ready: resb 1

section .text
init_cppapp:
    mov byte [cppapp_ready], 1
    ret

cppapp_launch:
    cmp byte [cppapp_ready], 1
    jne .done
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    mov rdi, NAVAPP_BIN_LBA
    mov rsi, NAVAPP_LOAD_PHYS
    mov rdx, NAVAPP_BIN_SECTORS
    call ata_read_sectors
    call NAVAPP_LOAD_PHYS
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
.done:
    ret
