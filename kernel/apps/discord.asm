; Navine OS - Discord client (local chat, Discord-style UI)

[BITS 64]

%include "constants.inc"

global init_discord
global app_open_discord
global discord_toggle
global discord_render
global discord_handle_key
global discord_handle_mouse
global discord_visible

extern fb_fill_rect
extern font_draw_string
extern mouse_x
extern mouse_y
extern mouse_buttons

section .bss
discord_visible:    resb 1
discord_server:     resb 1
discord_channel:    resb 1
discord_input_len:  resb 1
discord_input:      resb 80
discord_msg_count:  resb 1
discord_msgs:       resb 720
discord_mouse_last: resb 1

section .text
init_discord:
    mov byte [discord_visible], 0
    mov byte [discord_server], 0
    mov byte [discord_channel], 0
    mov byte [discord_input_len], 0
    mov byte [discord_msg_count], 0
    mov byte [discord_mouse_last], 0
    lea rdi, [discord_input]
    xor eax, eax
    mov ecx, 80
    rep stosb
    call discord_load_channel
    call discord_try_gateway
    ret

discord_try_gateway:
    lea rdi, [config_discord_token]
    cmp byte [rdi], 0
    je .out
    lea rdi, [dg_host]
    lea rdx, [dg_path]
    call ws_connect
    test rax, rax
    jz .out
    lea rdi, [NET_PKT_BUF_PHYS + 512]
    lea rsi, [dg_identify_head]
.copy_h:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .copy_t
    inc rsi
    inc rdi
    jmp .copy_h
.copy_t:
    lea rsi, [config_discord_token]
.copy_token:
    mov al, [rsi]
    test al, al
    jz .copy_tail
    mov [rdi], al
    inc rsi
    inc rdi
    jmp .copy_token
.copy_tail:
    lea rsi, [dg_identify_tail]
.copy_end:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .send
    inc rsi
    inc rdi
    jmp .copy_end
.send:
    mov rax, rdi
    sub rax, NET_PKT_BUF_PHYS + 512
    mov esi, eax
    lea rdx, [NET_PKT_BUF_PHYS + 512]
    call ws_send_text
.out:
    ret

discord_log_line:
    lea rdi, [log_path]
    call navinefs_lookup
    cmp eax, -1
    je .out
    mov edi, eax
    lea r8, [discord_input]
    mov edx, 80
    call navinefs_write
.out:
    ret

app_open_discord:
    mov byte [discord_visible], 1
    ret

discord_toggle:
    xor byte [discord_visible], 1
    ret

discord_render:
    cmp byte [discord_visible], 0
    je .done
    mov edi, 88
    mov esi, 52
    mov edx, 1128
    mov ecx, 656
    mov r8d, 0x66000000
    call fb_fill_rect
    mov edi, 80
    mov esi, 46
    mov edx, 1120
    mov ecx, 648
    mov r8d, 0xFF36393F
    call fb_fill_rect
    mov edi, 80
    mov esi, 46
    mov edx, 1120
    mov ecx, 42
    mov r8d, 0xFF202225
    call fb_fill_rect
    mov edi, 80
    mov esi, 46
    mov edx, 4
    mov ecx, 648
    mov r8d, 0xFF5865F2
    call fb_fill_rect
    mov edi, 96
    mov esi, 58
    lea rdx, [dc_title]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 1160
    mov esi, 54
    mov edx, 22
    mov ecx, 22
    mov r8d, 0xFFED4245
    call fb_fill_rect
    mov edi, 1165
    mov esi, 58
    lea rdx, [dc_close]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 80
    mov esi, 88
    mov edx, 72
    mov ecx, 606
    mov r8d, 0xFF202225
    call fb_fill_rect
    mov edi, 152
    mov esi, 88
    mov edx, 220
    mov ecx, 606
    mov r8d, 0xFF2F3136
    call fb_fill_rect
    mov edi, 152
    mov esi, 88
    mov edx, 220
    mov ecx, 48
    mov r8d, 0xFF202225
    call fb_fill_rect
    mov edi, 164
    mov esi, 102
    call discord_server_name_ptr
    mov ecx, COLOR_WHITE
    call font_draw_string
    call discord_render_servers
    call discord_render_channels
    mov edi, 384
    mov esi, 88
    mov edx, 816
    mov ecx, 48
    mov r8d, 0xFF36393F
    call fb_fill_rect
    mov edi, 396
    mov esi, 102
    lea rdx, [dc_hash]
    mov ecx, 0xFF72767D
    call font_draw_string
    mov edi, 408
    mov esi, 102
    call discord_channel_name_ptr
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 384
    mov esi, 136
    mov edx, 816
    mov ecx, 480
    mov r8d, 0xFF36393F
    call fb_fill_rect
    call discord_render_messages
    mov edi, 396
    mov esi, 628
    mov edx, 792
    mov ecx, 52
    mov r8d, 0xFF40444B
    call fb_fill_rect
    mov edi, 412
    mov esi, 646
    lea rdx, [discord_input]
    test byte [discord_input_len], 0
    jnz .show_input
    lea rdx, [dc_placeholder]
    mov ecx, 0xFF72767D
    jmp .draw_input
.show_input:
    mov ecx, 0xFFDCDDDE
.draw_input:
    call font_draw_string
    mov edi, 396
    mov esi, 688
    lea rdx, [dc_hint]
    mov ecx, 0xFF72767D
    call font_draw_string
.done:
    ret

discord_render_servers:
    push rbx
    xor ebx, ebx
.sloop:
    cmp bl, 3
    jae .out
    movzx eax, bl
    imul eax, 64
    add eax, 108
    mov esi, eax
    mov edi, 92
    mov edx, 48
    mov ecx, 48
    cmp bl, [discord_server]
    je .sel
    mov r8d, 0xFF36393F
    jmp .draw
.sel:
    mov r8d, 0xFF5865F2
.draw:
    call fb_fill_rect
    cmp bl, 0
    je .c0
    cmp bl, 1
    je .c1
    mov r8d, 0xFFFAA61A
    jmp .inner
.c0:
    mov r8d, 0xFF5865F2
    jmp .inner
.c1:
    mov r8d, 0xFF3BA55C
.inner:
    push rbx
    mov edi, 100
    add esi, 8
    mov edx, 32
    mov ecx, 32
    call fb_fill_rect
    pop rbx
    mov edi, 108
    mov esi, ebx
    imul esi, 64
    add esi, 124
    lea rdx, [dc_srv_icons + rbx]
    mov ecx, COLOR_WHITE
    call font_draw_string
    inc bl
    jmp .sloop
.out:
    pop rbx
    ret

discord_render_channels:
    push rbx
    xor ebx, ebx
.cloop:
    cmp bl, 3
    jae .out
    movzx eax, bl
    imul eax, 36
    add eax, 148
    mov esi, eax
    mov edi, 160
    mov edx, 200
    mov ecx, 32
    cmp bl, [discord_channel]
    je .active
    mov r8d, 0xFF2F3136
    jmp .draw
.active:
    mov r8d, 0xFF40444B
.draw:
    call fb_fill_rect
    mov edi, 172
    add esi, 8
    lea rdx, [dc_hash]
    mov ecx, 0xFF72767D
    call font_draw_string
    mov edi, 184
    movzx eax, byte [discord_server]
    imul eax, 3
    add eax, ebx
    lea rdx, [dc_channel_names]
    imul rax, 16
    add rdx, rax
    mov ecx, 0xFFDCDDDE
    call font_draw_string
    inc bl
    jmp .cloop
.out:
    pop rbx
    ret

discord_render_messages:
    push rbx
    xor ebx, ebx
    mov esi, 152
.mloop:
    movzx eax, byte [discord_msg_count]
    cmp ebx, eax
    jae .out
    mov edi, 396
    movzx eax, bl
    imul eax, 72
    lea rdx, [discord_msgs + rax]
    mov ecx, 0xFFDCDDDE
    call font_draw_string
    add esi, 22
    inc ebx
    cmp esi, 600
    jl .mloop
.out:
    pop rbx
    ret

discord_handle_key:
    cmp byte [discord_visible], 0
    je .no
    cmp dl, 0x01
    jne .not_esc
    mov byte [discord_visible], 0
    mov eax, 1
    ret
.not_esc:
    cmp dl, 0x1C
    je .send
    cmp dl, 0x0E
    je .backspace
    call discord_scancode_ascii
    test al, al
    jz .yes
    movzx ecx, byte [discord_input_len]
    cmp ecx, 79
    jae .yes
    lea rdi, [discord_input]
    mov [rdi + rcx], al
    inc byte [discord_input_len]
    mov byte [rdi + rcx + 1], 0
    jmp .yes
.backspace:
    cmp byte [discord_input_len], 0
    je .yes
    dec byte [discord_input_len]
    movzx ecx, byte [discord_input_len]
    lea rdi, [discord_input]
    mov byte [rdi + rcx], 0
    jmp .yes
.send:
    call discord_send_message
    jmp .yes
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

discord_scancode_ascii:
    cmp dl, 0x02
    jb .none
    cmp dl, 0x0B
    ja .alpha_chk
    movzx rax, dl
    sub rax, 0x02
    mov al, [dc_num_map + rax]
    ret
.alpha_chk:
    cmp dl, 0x10
    jb .none
    cmp dl, 0x35
    ja .none
    movzx rax, dl
    sub rax, 0x10
    mov al, [dc_key_map + rax]
    ret
.none:
    xor al, al
    ret

discord_append_line:
    push rsi
    movzx ecx, byte [discord_msg_count]
    cmp cl, 10
    jb .have_slot
    push rdi
    lea rsi, [discord_msgs + 72]
    lea rdi, [discord_msgs]
    mov ecx, 648
    rep movsb
    pop rdi
    mov byte [discord_msg_count], 9
.have_slot:
    pop rsi
    movzx eax, byte [discord_msg_count]
    imul eax, 72
    lea rdi, [discord_msgs + rax]
.copy:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .done
    inc rsi
    inc rdi
    jmp .copy
.done:
    inc byte [discord_msg_count]
    ret

discord_send_message:
    cmp byte [discord_input_len], 0
    je .out
    movzx eax, byte [discord_msg_count]
    cmp al, 10
    jb .slot_ok
    push rsi
    push rdi
    lea rsi, [discord_msgs + 72]
    lea rdi, [discord_msgs]
    mov ecx, 648
    rep movsb
    mov byte [discord_msg_count], 9
    pop rdi
    pop rsi
.slot_ok:
    movzx eax, byte [discord_msg_count]
    imul eax, 72
    lea rdi, [discord_msgs + rax]
    lea rsi, [dc_you_prefix]
.copy_prefix:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .copy_body
    inc rsi
    inc rdi
    jmp .copy_prefix
.copy_body:
    lea rsi, [discord_input]
.body:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .cleared
    inc rsi
    inc rdi
    jmp .body
.cleared:
    inc byte [discord_msg_count]
    mov byte [discord_input_len], 0
    lea rdi, [discord_input]
    mov byte [rdi], 0
    lea rsi, [dc_bot_reply]
    call discord_append_line
    call discord_log_line
.out:
    ret

discord_handle_mouse:
    cmp byte [discord_visible], 0
    je .done
    mov al, [mouse_buttons]
    mov bl, [discord_mouse_last]
    mov [discord_mouse_last], al
    test al, 1
    jz .done
    test bl, 1
    jnz .done
    mov eax, [mouse_x]
    cmp eax, 1156
    jl .not_close
    cmp eax, 1188
    jg .not_close
    mov eax, [mouse_y]
    cmp eax, 50
    jl .not_close
    cmp eax, 82
    jg .not_close
    mov byte [discord_visible], 0
    jmp .done
.not_close:
    mov eax, [mouse_x]
    cmp eax, 80
    jl .done
    cmp eax, 152
    jg .not_server
    mov eax, [mouse_y]
    cmp eax, 108
    jl .done
    cmp eax, 300
    jg .done
    sub eax, 108
    xor edx, edx
    mov ecx, 64
    div ecx
    cmp eax, 2
    ja .done
    mov [discord_server], al
    mov byte [discord_channel], 0
    call discord_load_channel
    jmp .done
.not_server:
    mov eax, [mouse_x]
    cmp eax, 152
    jl .done
    cmp eax, 372
    jg .done
    mov eax, [mouse_y]
    cmp eax, 148
    jl .done
    cmp eax, 256
    jg .done
    sub eax, 148
    xor edx, edx
    mov ecx, 36
    div ecx
    cmp eax, 2
    ja .done
    mov [discord_channel], al
    call discord_load_channel
.done:
    ret

discord_load_channel:
    mov byte [discord_msg_count], 0
    lea rdi, [discord_msgs]
    xor eax, eax
    mov ecx, 720
    rep stosb
    movzx eax, byte [discord_server]
    imul eax, 3
    movzx ebx, byte [discord_channel]
    add eax, ebx
    lea r8, [dc_seed_ptrs]
    shl rax, 3
    add r8, rax
    xor ebx, ebx
.seed_loop:
    cmp bl, 3
    jae .seed_done
    mov rsi, [r8 + rbx * 8]
    test rsi, rsi
    jz .seed_done
    call discord_append_line
    inc bl
    jmp .seed_loop
.seed_done:
    ret

discord_server_name_ptr:
    movzx eax, byte [discord_server]
    lea rdx, [dc_srv_names]
    imul rax, 16
    add rdx, rax
    ret

discord_channel_name_ptr:
    movzx eax, byte [discord_server]
    imul eax, 3
    movzx ebx, byte [discord_channel]
    add eax, ebx
    lea rdx, [dc_channel_names]
    imul rax, 16
    add rdx, rax
    ret

section .rodata
dc_title:       db "Discord", 0
dc_close:       db "X", 0
dc_hash:        db "#", 0
dc_placeholder: db "Message channel", 0
dc_hint:        db "Enter send  Esc close  F10 toggle  terminal: discord", 0
dc_you_prefix:  db "You: ", 0
dc_bot_reply:   db "NavineBot: Message received on local relay.", 0
dc_srv_icons:   db "N", 0, "G", 0, "D", 0, 0

dc_srv_names:
    db "Navine HQ", 0
    times 5 db 0
    db "Gaming", 0
    times 8 db 0
    db "Developers", 0
    times 4 db 0

dc_channel_names:
    db "general", 0
    times 9 db 0
    db "announcements", 0
    times 3 db 0
    db "help", 0
    times 12 db 0
    db "lobby", 0
    times 11 db 0
    db "doom", 0
    times 12 db 0
    db "grid", 0
    times 12 db 0
    db "kernel", 0
    times 10 db 0
    db "build", 0
    times 11 db 0
    db "debug", 0
    times 11 db 0

dc_num_map:     db "1234567890"
dc_key_map:
    db "qwertyuiop", 0, 0, 0, 0, "asdfghjkl", 0, 0, 0, 0, 0, "zxcvbnm"

seed_n0_0: db "NavineBot: Welcome to Navine Discord!", 0
seed_n0_1: db "System: Local chat works offline.", 0
seed_n0_2: db "NavineBot: Press Enter to send.", 0
seed_n1_0: db "Team: Navine OS Hybrid Edition shipped.", 0
seed_n1_1: db "Team: Game Mode and Dev Mode are live.", 0
seed_n2_0: db "NavineBot: Type discord in terminal.", 0
seed_n2_1: db "NavineBot: F10 toggles this window.", 0
seed_g0_0: db "Player1: anyone up for DOOM?", 0
seed_g0_1: db "Player2: grid-pack is installed.", 0
seed_g1_0: db "Player1: F12 launches DOOM.", 0
seed_g1_1: db "NavineBot: Store > Play for games.", 0
seed_g2_0: db "System: Navine Grid ready.", 0
seed_d0_0: db "Dev: asm kernel looking good.", 0
seed_d0_1: db "Dev: compositor and mouse fixed.", 0
seed_d1_0: db "Dev: build.bat works with nasm.", 0
seed_d1_1: db "Dev: serial.log for boot debug.", 0
seed_d2_0: db "Dev: discord command opens chat.", 0

dg_host: db "gateway.discord.gg", 0
dg_path: db "/?v=10&encoding=json", 0
dg_identify_head: db '{"op":2,"d":{"token":"', 0
dg_identify_tail: db '","properties":{"$os":"navine","$browser":"navine","$device":"navine"}}}', 0
log_path: db "discord.log", 0

dc_seed_ptrs:
    dq seed_n0_0, seed_n0_1, seed_n0_2, 0
    dq seed_n1_0, seed_n1_1, 0
    dq seed_n2_0, seed_n2_1, 0
    dq seed_g0_0, seed_g0_1, 0
    dq seed_g1_0, seed_g1_1, 0
    dq seed_g2_0, 0
    dq seed_d0_0, seed_d0_1, 0
    dq seed_d1_0, seed_d1_1, 0
    dq seed_d2_0, 0
