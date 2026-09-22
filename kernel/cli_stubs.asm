; Navine OS - CLI edition stubs for desktop-only symbols

[BITS 64]

global desktop_handle_key
global desktop_toggle_spotlight
global filetype_run

section .text
desktop_handle_key:
    xor eax, eax
    ret

desktop_toggle_spotlight:
    ret

filetype_run:
    ret
