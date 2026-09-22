; Navine OS - PS/2 Keyboard Driver

[BITS 64]

%include "constants.inc"
%include "macros.inc"

%ifndef NAVINE_LINK_BUILD
extern mouse_process_byte
extern mouse_cycle
extern mouse_irq_active
%endif

global init_keyboard
global keyboard_handler
global keyboard_read
global keyboard_has_data
global ps2_poll_all

section .bss
key_buffer:     resb 256
key_read_pos:   resq 1
key_write_pos:  resq 1

section .text
init_keyboard:
    mov qword [key_read_pos], 0
    mov qword [key_write_pos], 0
    mov al, 0xAE
    OUTB PS2_COMMAND_PORT, al
    ret

keyboard_handler:
    INB PS2_DATA_PORT, al
    mov rcx, [key_write_pos]
    and rcx, 255
    mov [key_buffer + rcx], al
    inc qword [key_write_pos]
    ret

keyboard_has_data:
    mov rax, [key_write_pos]
    sub rax, [key_read_pos]
    ret

keyboard_read:
    mov rax, [key_read_pos]
    cmp rax, [key_write_pos]
    jge .empty
    and rax, 255
    movzx rax, byte [key_buffer + rax]
    inc qword [key_read_pos]
    ret
.empty:
    xor rax, rax
    ret

ps2_poll_all:
    xor r9d, r9d
    pushfq
    cli
.poll:
    mov dx, PS2_STATUS_PORT
    in al, dx
    test al, 1
    jz .done
    mov bl, al
    test bl, 0x20
    jz .read
    cmp byte [mouse_irq_active], 0
    jne .done
.read:
    mov dx, PS2_DATA_PORT
    in al, dx
    test bl, 0x20
    jnz .mouse_byte
    cmp byte [mouse_cycle], 0
    jne .mouse_byte
    test al, 0x08
    jz .key_byte
    test al, 0xC0
    jnz .key_byte
.mouse_byte:
    call mouse_process_byte
    jmp .poll
.key_byte:
    mov rcx, [key_write_pos]
    and rcx, 255
    mov [key_buffer + rcx], al
    inc qword [key_write_pos]
    jmp .poll
.done:
    popfq
    mov eax, r9d
    ret
