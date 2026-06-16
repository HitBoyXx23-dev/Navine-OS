; Navine OS - IDT and interrupt handlers

[BITS 64]

%include "constants.inc"
%include "macros.inc"

%ifndef NAVINE_LINK_BUILD
extern pic_send_eoi
extern scheduler_tick
extern keyboard_handler
extern mouse_handler
%endif

global init_idt
global irq_dispatch
global exception_dispatch

section .bss
idt:            resb 256 * 16
idtr:           resb 10         ; 2-byte limit + 8-byte base (64-bit IDTR)

section .text
init_idt:
    mov rdi, idt
    xor rcx, rcx
.fill:
    mov rax, isr_stub
    mov word [rdi], ax          ; offset[15:0]
    mov word [rdi + 2], 0x08    ; code segment selector
    mov byte [rdi + 4], 0       ; IST = 0
    mov byte [rdi + 5], 0x8E    ; P=1, DPL=0, type=0xE (64-bit interrupt gate)
    mov r8, rax
    shr r8, 16
    mov word [rdi + 6], r8w     ; offset[31:16]
    shr r8, 16
    mov dword [rdi + 8], r8d    ; offset[63:32]
    add rdi, 16
    inc rcx
    cmp rcx, 256
    jl .fill
    mov word [idtr], 256 * 16 - 1
    mov qword [idtr + 2], idt
    lidt [idtr]
    ret

isr_stub:
    iretq

irq_dispatch:
    ; rdi = irq number
    cmp rdi, 0
    je .timer
    cmp rdi, 1
    je .keyboard
    cmp rdi, 12
    je .mouse
    jmp .eoi
.timer:
    call scheduler_tick
    jmp .eoi
.keyboard:
    call keyboard_handler
    jmp .eoi
.mouse:
    call mouse_handler
    jmp .eoi
.eoi:
    mov rdi, rax
    call pic_send_eoi
    ret

exception_dispatch:
    mov rsi, exc_msg
    call kernel_panic
    ret

section .rodata
exc_msg: db "Kernel exception", 0

global kernel_panic
kernel_panic:
    cli
.halt:
    hlt
    jmp .halt
