; Navine OS - Plugin System (.nplugin)

[BITS 64]

global plugin_init
global plugin_load
global plugin_reload

section .bss
plugin_table:   resb 1024
plugin_count:   resd 1

section .text
plugin_init:
    mov dword [plugin_count], 0
    ret

plugin_load:
    inc dword [plugin_count]
    ret

plugin_reload:
    ret
