; Navine OS - Assembly Macros

%ifndef NAVINE_MACROS_INC
%define NAVINE_MACROS_INC

%macro PUSH_ALL 0
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push rbp
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
%endmacro

%macro POP_ALL 0
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rbp
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
%endmacro

%macro OUTB 2
    mov dx, %1
    mov al, %2
    out dx, al
%endmacro

%macro INB 2
    mov dx, %1
    in al, dx
    mov %2, al
%endmacro

%macro OUTW 2
    mov dx, %1
    mov ax, %2
    out dx, ax
%endmacro

%macro INW 2
    mov dx, %1
    in ax, dx
    mov %2, ax
%endmacro

%macro OUTD 2
    mov dx, %1
    mov eax, %2
    out dx, eax
%endmacro

%macro IND 2
    mov dx, %1
    in eax, dx
    mov %2, eax
%endmacro

%macro CLI_HALT 0
    cli
.halt_loop:
    hlt
    jmp .halt_loop
%endmacro

%macro SET_GDT 2
    lgdt [%1]
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp %2
%endmacro

%macro IRQ_HANDLER 1
global isr_%1
isr_%1:
    PUSH_ALL
    mov rdi, %1
    call irq_dispatch
    POP_ALL
    iretq
%endmacro

%macro EXCEPTION_HANDLER 1
global isr_%1
isr_%1:
    PUSH_ALL
    mov rdi, %1
    call exception_dispatch
    POP_ALL
    iretq
%endmacro

%endif
