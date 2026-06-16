; Navine OS - PIT timer (1000 Hz)

[BITS 64]

%include "constants.inc"
%include "macros.inc"

global init_pit
global pit_ticks

section .bss
pit_ticks:      resq 1

section .text
init_pit:
    mov qword [pit_ticks], 0
    mov al, 0x36
    OUTB PIT_COMMAND, al
    mov ax, 1193
    OUTB PIT_CHANNEL0, al
    mov al, ah
    OUTB PIT_CHANNEL0, al
    ret
