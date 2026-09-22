; Navine OS - PS/2 Mouse Driver

[BITS 64]

%include "constants.inc"
%include "macros.inc"

global init_mouse
global init_mouse_defaults
global mouse_handler
global mouse_poll
global mouse_process_byte
global mouse_render
global mouse_x
global mouse_y
global mouse_buttons
global mouse_cycle
global mouse_irq_active

%ifndef NAVINE_LINK_BUILD
extern fb_fill_rect
extern fb_width
extern fb_height
%endif

section .bss
mouse_x:        resd 1
mouse_y:        resd 1
mouse_buttons:  resb 1
mouse_cycle:    resb 1
mouse_packet:   resb 3
mouse_irq_active: resb 1

section .text
init_mouse_defaults:
    mov eax, [fb_width]
    test eax, eax
    jnz .have_w
    mov eax, VESA_WIDTH
.have_w:
    shr eax, 1
    mov [mouse_x], eax
    mov eax, [fb_height]
    test eax, eax
    jnz .have_h
    mov eax, VESA_HEIGHT
.have_h:
    shr eax, 1
    mov [mouse_y], eax
    mov byte [mouse_buttons], 0
    mov byte [mouse_cycle], 0
    ret

init_mouse:
    call init_mouse_defaults
    mov byte [mouse_irq_active], 0
    call ps2_wait_input
    mov al, 0xA8
    OUTB PS2_COMMAND_PORT, al
    call ps2_enable_irq_config
    mov al, 0xFF
    call mouse_send_command
    call mouse_drain
    mov al, 0xF6
    call mouse_send_command
    mov al, 0xE8
    call mouse_send_command
    mov al, 0x03
    call mouse_send_command
    mov al, 0xF3
    call mouse_send_command
    mov al, 0x64
    call mouse_send_command
    mov al, 0xF4
    call mouse_send_command
    mov byte [mouse_cycle], 0
    ret

ps2_enable_irq_config:
    push rbx
    call ps2_wait_input
    mov al, 0x20
    OUTB PS2_COMMAND_PORT, al
    call ps2_wait_output
    INB PS2_DATA_PORT, al
    or al, 0x03
    and al, 0xDF
    mov bl, al
    call ps2_wait_input
    mov al, 0x60
    OUTB PS2_COMMAND_PORT, al
    call ps2_wait_input
    OUTB PS2_DATA_PORT, bl
    pop rbx
    ret

mouse_drain:
    call ps2_wait_output
    INB PS2_DATA_PORT, al
    call ps2_wait_output
    INB PS2_DATA_PORT, al
    call ps2_wait_output
    INB PS2_DATA_PORT, al
    ret

ps2_wait_input:
    mov ecx, 100000
.loop:
    mov dx, PS2_STATUS_PORT
    in al, dx
    test al, 0x02
    jz .ready
    loop .loop
.ready:
    ret

ps2_wait_output:
    mov ecx, 100000
.loop:
    mov dx, PS2_STATUS_PORT
    in al, dx
    test al, 0x01
    jnz .ready
    loop .loop
.ready:
    ret

mouse_send_command:
    push rbx
    mov bl, al
    mov bh, 3
.attempt:
    call ps2_wait_input
    mov al, 0xD4
    OUTB PS2_COMMAND_PORT, al
    call ps2_wait_input
    OUTB PS2_DATA_PORT, bl
    call ps2_wait_output
    INB PS2_DATA_PORT, al
    cmp al, 0xFE
    jne .done
    dec bh
    jnz .attempt
.done:
    pop rbx
    ret

mouse_handler:
    mov byte [mouse_irq_active], 1
    INB PS2_DATA_PORT, al
    call mouse_process_byte
    ret

mouse_poll:
    xor r9d, r9d
    ret

mouse_process_byte:
    mov cl, [mouse_cycle]
    test cl, cl
    jnz .store
    test al, 0x08
    jz .done
    test al, 0xC0
    jnz .done
.store:
    movzx rcx, byte [mouse_cycle]
    mov [mouse_packet + rcx], al
    inc byte [mouse_cycle]
    cmp byte [mouse_cycle], 3
    jl .done
    mov byte [mouse_cycle], 0
    mov al, [mouse_packet]
    test al, 0xC0
    jnz .done
    mov [mouse_buttons], al
    movsx eax, byte [mouse_packet + 1]
    cmp eax, 24
    jle .dx_high_ok
    mov eax, 24
.dx_high_ok:
    cmp eax, -24
    jge .dx_low_ok
    mov eax, -24
.dx_low_ok:
    shl eax, 1
    add [mouse_x], eax
    movsx eax, byte [mouse_packet + 2]
    cmp eax, 24
    jle .dy_high_ok
    mov eax, 24
.dy_high_ok:
    cmp eax, -24
    jge .dy_low_ok
    mov eax, -24
.dy_low_ok:
    shl eax, 1
    sub [mouse_y], eax
    mov r9d, 1
.done:
    ret

mouse_render:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov eax, [mouse_x]
    cmp eax, 0
    jge .x_min_ok
    xor eax, eax
.x_min_ok:
    mov ecx, [fb_width]
    sub ecx, 24
    cmp eax, ecx
    jle .x_ok
    mov eax, ecx
.x_ok:
    mov [mouse_x], eax
    mov r12d, eax

    mov eax, [mouse_y]
    cmp eax, 0
    jge .y_min_ok
    xor eax, eax
.y_min_ok:
    mov ecx, [fb_height]
    sub ecx, 24
    cmp eax, ecx
    jle .y_ok
    mov eax, ecx
.y_ok:
    mov [mouse_y], eax
    mov r13d, eax

    lea r15, [cursor_rows]
    xor r14d, r14d
.shadow_loop:
    cmp r14d, 18
    jge .white_start
    movzx edx, byte [r15 + r14]
    test edx, edx
    jz .shadow_next
    mov edi, r12d
    add edi, 1
    mov esi, r13d
    add esi, r14d
    add esi, 1
    mov ecx, 1
    mov r8d, 0xFF000000
    call fb_fill_rect
.shadow_next:
    inc r14d
    jmp .shadow_loop

.white_start:
    xor r14d, r14d
.white_loop:
    cmp r14d, 18
    jge .done
    movzx edx, byte [r15 + r14]
    test edx, edx
    jz .white_next
    mov edi, r12d
    mov esi, r13d
    add esi, r14d
    mov ecx, 1
    mov r8d, COLOR_WHITE
    call fb_fill_rect
.white_next:
    inc r14d
    jmp .white_loop
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

section .rodata
cursor_rows:
    db 2,3,4,5,6,7,8,9,10,11,12,9,8,7,6,5,4,3
