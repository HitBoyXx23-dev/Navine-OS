; Navine OS - Game library and store launcher hooks

[BITS 64]

%ifndef NAVINE_LINK_BUILD
extern doom_launch
extern terminal_write
%endif

global game_library_init
global game_library_count
global game_library_name
global game_library_launch
global store_launch_steam
global store_launch_epic
global store_launch_gog

section .bss
game_lib_count: resd 1

section .text
game_library_init:
    mov dword [game_lib_count], 3
    ret

game_library_count:
    mov eax, [game_lib_count]
    ret

game_library_name:
    cmp edi, 0
    je .n0
    cmp edi, 1
    je .n1
    cmp edi, 2
    je .n2
    lea rax, [gl_name_none]
    ret
.n0:
    lea rax, [gl_name_doom]
    ret
.n1:
    lea rax, [gl_name_grid]
    ret
.n2:
    lea rax, [gl_name_demo]
    ret

game_library_launch:
    cmp edi, 0
    je .doom
    xor rax, rax
    ret
.doom:
    call doom_launch
    mov rax, 1
    ret

store_launch_steam:
    lea rdi, [msg_steam]
    call terminal_write
    mov rax, 1
    ret

store_launch_epic:
    lea rdi, [msg_epic]
    call terminal_write
    mov rax, 1
    ret

store_launch_gog:
    lea rdi, [msg_gog]
    call terminal_write
    mov rax, 1
    ret

section .rodata
gl_name_doom:  db "Navine Grid (DOOM)", 0
gl_name_grid:  db "Grid Demo", 0
gl_name_demo:  db "Vulkan Test", 0
gl_name_none:  db "-", 0
msg_steam:  db "Steam launcher: invoke external binary", 10, 0
msg_epic:   db "Epic launcher: invoke external binary", 10, 0
msg_gog:    db "GOG launcher: invoke external binary", 10, 0
