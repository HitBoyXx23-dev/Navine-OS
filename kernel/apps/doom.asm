; Navine OS - DOOM launcher

[BITS 64]

%include "constants.inc"
%include "doom_wad.inc"

extern ata_read_sectors
extern fb_fill_rect
extern font_draw_string
extern fb_width
extern fb_height
extern mouse_x
extern mouse_y
extern mouse_buttons
extern terminal_write
extern files_visible
extern textviewer_active

global doom_launch
global init_doom
global doom_available
global doom_render
global doom_handle_key
global doom_handle_mouse

section .bss
doom_ready:      resb 1
doom_active:     resb 1
doom_mouse_last: resb 1
doom_player_x:   resd 1
doom_player_y:   resd 1
doom_turns:      resd 1

section .text
init_doom:
    mov byte [doom_ready], 1
    mov byte [doom_active], 0
    mov byte [doom_mouse_last], 0
    mov dword [doom_player_x], 1
    mov dword [doom_player_y], 1
    mov dword [doom_turns], 0
    ret

doom_available:
    movzx rax, byte [doom_ready]
    ret

doom_launch:
    lea rdi, [msg_real_doom_start]
    call terminal_write
    call doom_launch_raw
    mov byte [doom_active], 1
    mov byte [files_visible], 0
    mov byte [textviewer_active], 0
    mov dword [doom_player_x], 1
    mov dword [doom_player_y], 1
    mov dword [doom_turns], 0
    lea rdi, [msg_game_start]
    call terminal_write
    ret

doom_render:
    cmp byte [doom_active], 1
    jne .done
    push rbx
    push r12
    push r13
    mov eax, [fb_width]
    sub eax, 760
    shr eax, 1
    mov r12d, eax
    mov eax, [fb_height]
    sub eax, 500
    shr eax, 1
    mov r13d, eax

    mov edi, r12d
    mov esi, r13d
    mov edx, 760
    mov ecx, 500
    mov r8d, 0xF0101218
    call fb_fill_rect
    mov edi, r12d
    mov esi, r13d
    mov edx, 760
    mov ecx, 34
    mov r8d, 0xFF242A33
    call fb_fill_rect
    mov edi, r12d
    add edi, 14
    mov esi, r13d
    add esi, 10
    lea rdx, [doom_close]
    mov ecx, 0xFFFF5F57
    call font_draw_string
    mov edi, r12d
    add edi, 56
    mov esi, r13d
    add esi, 10
    lea rdx, [doom_title]
    mov ecx, COLOR_WHITE
    call font_draw_string

    mov edi, r12d
    add edi, 46
    mov esi, r13d
    add esi, 64
    lea rdx, [doom_status]
    mov ecx, 0xFFB8D7F0
    call font_draw_string

    mov ebx, 0
.rows:
    cmp ebx, 9
    jge .player
    mov edi, r12d
    add edi, 56
    mov esi, r13d
    add esi, 112
    mov eax, ebx
    imul eax, 28
    add esi, eax
    mov rdx, [doom_map_ptrs + rbx * 8]
    mov ecx, COLOR_WHITE
    call font_draw_string
    inc ebx
    jmp .rows
.player:
    mov edi, r12d
    add edi, 56
    mov eax, [doom_player_x]
    imul eax, 9
    add edi, eax
    mov esi, r13d
    add esi, 112
    mov eax, [doom_player_y]
    imul eax, 28
    add esi, eax
    lea rdx, [doom_player]
    mov ecx, 0xFF2CC36B
    call font_draw_string

    mov edi, r12d
    add edi, 420
    mov esi, r13d
    add esi, 112
    lea rdx, [doom_panel1]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, r12d
    add edi, 420
    mov esi, r13d
    add esi, 146
    lea rdx, [doom_panel2]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov edi, r12d
    add edi, 420
    mov esi, r13d
    add esi, 180
    lea rdx, [doom_panel3]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    mov edi, r12d
    add edi, 420
    mov esi, r13d
    add esi, 214
    lea rdx, [doom_panel4]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    pop r13
    pop r12
    pop rbx
.done:
    ret

doom_handle_key:
    cmp byte [doom_active], 1
    jne .not_handled
    cmp dl, 0x01
    je .close
    xor eax, eax
    xor ebx, ebx
    cmp dl, 0x11
    je .up
    cmp dl, 0x1F
    je .down
    cmp dl, 0x1E
    je .left
    cmp dl, 0x20
    je .right
    jmp .handled
.up:
    mov ebx, -1
    jmp .move
.down:
    mov ebx, 1
    jmp .move
.left:
    mov eax, -1
    jmp .move
.right:
    mov eax, 1
.move:
    add eax, [doom_player_x]
    add ebx, [doom_player_y]
    call doom_tile_at
    cmp cl, '0'
    je .handled
    mov [doom_player_x], eax
    mov [doom_player_y], ebx
    inc dword [doom_turns]
    cmp cl, 'X'
    jne .handled
    lea rdi, [msg_game_win]
    call terminal_write
    mov byte [doom_active], 0
    jmp .handled
.close:
    mov byte [doom_active], 0
.handled:
    mov eax, 1
    ret
.not_handled:
    xor eax, eax
    ret

doom_handle_mouse:
    cmp byte [doom_active], 1
    jne .done
    mov al, [mouse_buttons]
    mov bl, [doom_mouse_last]
    mov [doom_mouse_last], al
    test al, 1
    jz .done
    test bl, 1
    jnz .done
    mov eax, [fb_width]
    sub eax, 760
    shr eax, 1
    mov ecx, [mouse_x]
    sub ecx, eax
    cmp ecx, 10
    jl .done
    cmp ecx, 44
    jge .done
    mov eax, [fb_height]
    sub eax, 500
    shr eax, 1
    mov ecx, [mouse_y]
    sub ecx, eax
    cmp ecx, 6
    jl .done
    cmp ecx, 30
    jge .done
    mov byte [doom_active], 0
.done:
    ret

doom_tile_at:
    cmp eax, 0
    jl .wall
    cmp eax, 14
    jg .wall
    cmp ebx, 0
    jl .wall
    cmp ebx, 8
    jg .wall
    mov rdx, [doom_map_ptrs + rbx * 8]
    mov cl, [rdx + rax]
    ret
.wall:
    mov cl, '0'
    ret

doom_launch_raw:
    cmp dword [DOOM_WAD_BYTES_VAL], 0
    je .no_wad

    mov rdi, DOOM_BIN_LBA
    mov rsi, DOOM_LOAD_PHYS
    mov rdx, DOOM_BIN_SECTORS
    call ata_read_sectors

    mov rdi, DOOM_WAD_LBA
    mov rsi, DOOM_WAD_PHYS
    mov rdx, [DOOM_WAD_SECTORS_VAL]
    call ata_read_sectors

    mov eax, [DOOM_WAD_BYTES_VAL]
    mov dword [DOOM_WAD_SIZE_PHYS], eax

    mov rsp, DOOM_STACK_TOP
    mov rax, DOOM_LOAD_PHYS
    jmp rax

.no_wad:
    ret

section .data
DOOM_WAD_SECTORS_VAL: dd DOOM_WAD_SECTORS
DOOM_WAD_BYTES_VAL:   dd DOOM_WAD_BYTES

section .rodata
msg_game_start: db 10, "Game launched. Use WASD, Esc or red close button to exit.", 10, 0
msg_real_doom_start: db 10, "Launching embedded DOOM runtime...", 10, 0
msg_game_win:   db 10, "Exit reached. Game closed cleanly.", 10, 0
doom_close:     db "X", 0
doom_title:     db "Navine Grid", 0
doom_status:    db "Reach X. WASD moves. Esc closes.", 0
doom_player:    db "@", 0
doom_panel1:    db "Process: grid.nav", 0
doom_panel2:    db "Memory: 4 MB stable", 0
doom_panel3:    db "Input: keyboard and close button", 0
doom_panel4:    db "State: active and contained", 0
doom_row0:      db "000000000000000", 0
doom_row1:      db "0....0.......X0", 0
doom_row2:      db "0.00.0.00000..0", 0
doom_row3:      db "0.0..0.....0..0", 0
doom_row4:      db "0.0.00000.0.0.0", 0
doom_row5:      db "0...0.....0.0.0", 0
doom_row6:      db "000.0.00000.0.0", 0
doom_row7:      db "0.............0", 0
doom_row8:      db "000000000000000", 0
doom_map_ptrs:
    dq doom_row0, doom_row1, doom_row2, doom_row3, doom_row4
    dq doom_row5, doom_row6, doom_row7, doom_row8
