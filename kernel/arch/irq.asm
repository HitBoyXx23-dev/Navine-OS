; Navine OS - IRQ stubs (timer)

[BITS 64]

%include "constants.inc"

global init_irq_vectors
global irq0_handler
global irq1_handler
global irq12_handler

section .text
init_irq_vectors:
    mov rdi, idt
    add rdi, 32 * 16
    mov rax, irq0_handler
    mov word [rdi], ax
    mov word [rdi + 2], 0x08
    mov byte [rdi + 4], 0
    mov byte [rdi + 5], 0x8E
    mov r8, rax
    shr r8, 16
    mov word [rdi + 6], r8w
    shr r8, 16
    mov dword [rdi + 8], r8d
    mov rdi, idt
    add rdi, 33 * 16
    mov rax, irq1_handler
    mov word [rdi], ax
    mov word [rdi + 2], 0x08
    mov byte [rdi + 4], 0
    mov byte [rdi + 5], 0x8E
    mov r8, rax
    shr r8, 16
    mov word [rdi + 6], r8w
    shr r8, 16
    mov dword [rdi + 8], r8d
    mov rdi, idt
    add rdi, 44 * 16
    mov rax, irq12_handler
    mov word [rdi], ax
    mov word [rdi + 2], 0x08
    mov byte [rdi + 4], 0
    mov byte [rdi + 5], 0x8E
    mov r8, rax
    shr r8, 16
    mov word [rdi + 6], r8w
    shr r8, 16
    mov dword [rdi + 8], r8d
    ret

irq0_handler:
    push rax
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    call scheduler_tick
    call kernel_net_tick
    xor rdi, rdi
    call pic_send_eoi
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rax
    iretq

irq1_handler:
    push rax
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    call keyboard_handler
    xor rdi, rdi
    call pic_send_eoi
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rax
    iretq

irq12_handler:
    push rax
    push rbx
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    call mouse_handler
    mov rdi, 12
    call pic_send_eoi
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rbx
    pop rax
    iretq
