; Navine OS - IDT and interrupt handlers

[BITS 64]

%include "constants.inc"
%include "macros.inc"

%ifndef NAVINE_LINK_BUILD
extern pic_send_eoi
extern scheduler_tick
extern keyboard_handler
extern mouse_handler
extern init_irq_vectors
extern kernel_panic
%endif

global init_idt
global irq_dispatch
global exception_dispatch
global idt

section .bss
idt:            resb 256 * 16
idtr:           resb 10

section .rodata
align 8
exception_stubs:
    dq exc_0, exc_1, exc_2, exc_3, exc_4, exc_5, exc_6, exc_7
    dq exc_8, exc_9, exc_10, exc_11, exc_12, exc_13, exc_14, exc_15
    dq exc_16, exc_17, exc_18, exc_19, exc_20, exc_21, exc_22, exc_23
    dq exc_24, exc_25, exc_26, exc_27, exc_28, exc_29, exc_30, exc_31

section .text
init_idt:
    mov rdi, idt
    xor rcx, rcx
.fill:
    cmp rcx, 32
    jae .default_stub
    mov rax, [exception_stubs + rcx * 8]
    jmp .install
.default_stub:
    mov rax, isr_stub
.install:
    mov word [rdi], ax
    mov word [rdi + 2], 0x08
    mov byte [rdi + 4], 0
    mov byte [rdi + 5], 0x8E
    mov r8, rax
    shr r8, 16
    mov word [rdi + 6], r8w
    shr r8, 16
    mov dword [rdi + 8], r8d
    add rdi, 16
    inc rcx
    cmp rcx, 256
    jl .fill
    mov word [idtr], 256 * 16 - 1
    mov qword [idtr + 2], idt
    lidt [idtr]
    call init_irq_vectors
    ret

%macro EXC_NOERR 1
align 16
exc_%1:
    cli
    push qword 0
    push %1
    jmp exc_common
%endmacro

%macro EXC_ERR 1
align 16
exc_%1:
    cli
    push %1
    jmp exc_common
%endmacro

EXC_NOERR 0
EXC_NOERR 1
EXC_NOERR 2
EXC_NOERR 3
EXC_NOERR 4
EXC_NOERR 5
EXC_NOERR 6
EXC_NOERR 7
EXC_ERR 8
EXC_NOERR 9
EXC_ERR 10
EXC_ERR 11
EXC_ERR 12
EXC_ERR 13
EXC_ERR 14
EXC_NOERR 15
EXC_NOERR 16
EXC_ERR 17
EXC_NOERR 18
EXC_NOERR 19
EXC_NOERR 20
EXC_NOERR 21
EXC_NOERR 22
EXC_NOERR 23
EXC_NOERR 24
EXC_NOERR 25
EXC_NOERR 26
EXC_NOERR 27
EXC_NOERR 28
EXC_NOERR 29
EXC_NOERR 30
EXC_NOERR 31

exc_common:
    mov rsi, exc_msg
    call kernel_panic
    cli
    hlt
    jmp $

isr_stub:
    iretq

irq_dispatch:
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
exc_msg: db "CPU exception", 0
