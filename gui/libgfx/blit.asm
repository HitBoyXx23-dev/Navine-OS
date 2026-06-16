; gui/libgfx/blit.asm
[BITS 64]
global gui_blit32
section .text
gui_blit32:
    mov rcx, rdx
    rep movsd
    ret
