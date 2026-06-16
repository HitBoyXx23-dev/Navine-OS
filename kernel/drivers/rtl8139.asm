; Navine OS - RTL8139 Network Driver

[BITS 64]

global init_rtl8139
global rtl8139_send
global rtl8139_recv

section .text
init_rtl8139:
    ret

rtl8139_send:
    ret

rtl8139_recv:
    xor rax, rax
    ret
