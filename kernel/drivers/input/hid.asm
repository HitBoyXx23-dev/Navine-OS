; Navine OS - USB HID controller manager stub

[BITS 64]

global hid_init
global hid_poll
global hid_controller_count
global hid_controller_connected

section .bss
hid_ctrl_count: resb 1
hid_last_buttons: resd 1

section .text
hid_init:
    mov byte [hid_ctrl_count], 0
    mov dword [hid_last_buttons], 0
    ret

hid_poll:
    ret

hid_controller_count:
    movzx rax, byte [hid_ctrl_count]
    ret

hid_controller_connected:
    cmp byte [hid_ctrl_count], 0
    seta al
    movzx rax, al
    ret
