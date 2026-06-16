; Navine OS - PS/2 Keyboard Driver

[BITS 64]

%include "constants.inc"
%include "macros.inc"

%ifndef NAVINE_LINK_BUILD
extern mouse_process_byte
%endif

global init_keyboard
global keyboard_handler
global keyboard_read
global keyboard_has_data

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
    call keyboard_poll
    mov rax, [key_write_pos]
    sub rax, [key_read_pos]
    ret

keyboard_read:
    call keyboard_poll
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

keyboard_poll:
.poll:
    mov dx, PS2_STATUS_PORT
    in al, dx
    test al, 1
    jz .done
    test al, 0x20
    jnz .mouse_byte
    mov dx, PS2_DATA_PORT
    in al, PS2_DATA_PORT
    mov rcx, [key_write_pos]
    and rcx, 255
    mov [key_buffer + rcx], al
    inc qword [key_write_pos]
    jmp .poll
.mouse_byte:
    mov dx, PS2_DATA_PORT
    in al, dx
    call mouse_process_byte
    jmp .poll
.done:
    ret
