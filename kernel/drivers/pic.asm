; Navine OS - PIC remapping

[BITS 64]

%include "constants.inc"
%include "macros.inc"

global init_pic
global pic_send_eoi

section .text
init_pic:
    mov al, 0x11
    OUTB PIC1_COMMAND, al
    OUTB PIC2_COMMAND, al
    mov al, 0x20
    OUTB PIC1_DATA, al
    mov al, 0x28
    OUTB PIC2_DATA, al
    mov al, 0x04
    OUTB PIC1_DATA, al
    mov al, 0x02
    OUTB PIC2_DATA, al
    mov al, 0x01
    OUTB PIC1_DATA, al
    OUTB PIC2_DATA, al
    mov al, 0xFF
    OUTB PIC1_DATA, al
    mov al, 0xFF
    OUTB PIC2_DATA, al
    ret

pic_send_eoi:
    cmp rdi, 8
    jl .master
    mov al, PIC_EOI
    OUTB PIC2_COMMAND, al
.master:
    mov al, PIC_EOI
    OUTB PIC1_COMMAND, al
    ret
