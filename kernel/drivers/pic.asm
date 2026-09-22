; Navine OS - PIC remapping

[BITS 64]

%include "constants.inc"
%include "macros.inc"

global init_pic
global pic_send_eoi
global pic_unmask_irq
global pic_unmask_timer
global pic_unmask_keyboard
global pic_unmask_mouse

section .bss
pic_mask1: resb 1
pic_mask2: resb 1

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
    mov byte [pic_mask1], 0xFF
    mov byte [pic_mask2], 0xFF
    mov al, 0xFF
    OUTB PIC1_DATA, al
    mov al, 0xFF
    OUTB PIC2_DATA, al
    ret

pic_unmask_irq:
    cmp rdi, 8
    jge .slave
    mov rcx, rdi
    mov al, 1
    shl al, cl
    not al
    and [pic_mask1], al
    mov al, [pic_mask1]
    OUTB PIC1_DATA, al
    ret
.slave:
    mov rcx, rdi
    sub rcx, 8
    mov al, 1
    shl al, cl
    not al
    and [pic_mask2], al
    mov al, [pic_mask2]
    OUTB PIC2_DATA, al
    mov rdi, 2
    jmp pic_unmask_irq

pic_unmask_keyboard:
    mov rdi, 1
    jmp pic_unmask_irq

pic_unmask_timer:
    mov rdi, 0
    call pic_unmask_irq
    mov rdi, 1
    jmp pic_unmask_irq

pic_unmask_mouse:
    mov rdi, 12
    jmp pic_unmask_irq

pic_send_eoi:
    cmp rdi, 8
    jl .master
    mov al, PIC_EOI
    OUTB PIC2_COMMAND, al
.master:
    mov al, PIC_EOI
    OUTB PIC1_COMMAND, al
    ret
