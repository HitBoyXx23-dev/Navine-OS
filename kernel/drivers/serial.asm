; Navine OS - COM1 serial debug output

[BITS 64]

%include "constants.inc"

global init_serial
global serial_puts
global serial_puthex
global serial_putc
global debug_boot_info

section .text
init_serial:
    mov dx, 0x3F9
    xor al, al
    out dx, al
    mov dx, 0x3FB
    mov al, 0x80
    out dx, al
    mov dx, 0x3F8
    mov al, 1
    out dx, al
    mov dx, 0x3F9
    xor al, al
    out dx, al
    mov dx, 0x3FB
    mov al, 0x03
    out dx, al
    mov dx, 0x3FA
    mov al, 0xC7
    out dx, al
    mov dx, 0x3FC
    mov al, 0x0B
    out dx, al
    ret

serial_putc:
    push rdx
    push rax
.wait:
    mov dx, 0x3FD
    in al, dx
    test al, 0x20
    jz .wait
    pop rax
    push rax
    mov dx, 0x3F8
    out dx, al
    pop rax
    pop rdx
    ret

serial_puts:
    push rsi
    push rax
.loop:
    mov al, [rsi]
    test al, al
    jz .done
    call serial_putc
    inc rsi
    jmp .loop
.done:
    pop rax
    pop rsi
    ret

serial_puthex:
    push rbx
    push rcx
    mov rbx, rax
    mov cx, 16
.next:
    rol rbx, 4
    mov al, bl
    and al, 0x0F
    cmp al, 10
    jb .dig
    add al, 'A' - 10
    jmp .put
.dig:
    add al, '0'
.put:
    call serial_putc
    dec cx
    jnz .next
    pop rcx
    pop rbx
    ret

debug_boot_info:
    lea rsi, [d_hello]
    call serial_puts
    lea rsi, [d_base]
    call serial_puts
    mov rax, FB_INFO_PHYS
    mov rax, [rax]
    call serial_puthex
    call .nl
    lea rsi, [d_w]
    call serial_puts
    mov rax, FB_INFO_PHYS
    movzx rax, word [rax + 8]
    call serial_puthex
    call .nl
    lea rsi, [d_h]
    call serial_puts
    mov rax, FB_INFO_PHYS
    movzx rax, word [rax + 12]
    call serial_puthex
    call .nl
    lea rsi, [d_pitch]
    call serial_puts
    mov rax, FB_INFO_PHYS
    movzx rax, word [rax + 16]
    call serial_puthex
    call .nl
    lea rsi, [d_bpp]
    call serial_puts
    mov rax, FB_INFO_PHYS
    movzx rax, word [rax + 20]
    call serial_puthex
    call .nl
    lea rsi, [d_gfxok]
    call serial_puts
    mov rax, FB_INFO_PHYS
    movzx rax, byte [rax + 24]
    call serial_puthex
    call .nl
    ret
.nl:
    mov al, 13
    call serial_putc
    mov al, 10
    call serial_putc
    ret

section .rodata
d_hello: db "NAVINE BOOT: kernel entered long mode", 13, 10, 0
d_base:  db "  fb_base  = 0x", 0
d_w:     db "  width    = 0x", 0
d_h:     db "  height   = 0x", 0
d_pitch: db "  pitch    = 0x", 0
d_bpp:   db "  bpp      = 0x", 0
d_gfxok: db "  gfx_ok   = 0x", 0
