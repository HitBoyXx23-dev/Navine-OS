; Navine OS - NavineFS config persistence (/config/navine.cfg)

[BITS 64]

global config_load
global config_save
global config_discord_token
global config_dock_visible
global config_game_mode
global config_dev_mode

section .bss
config_discord_token: resb 128
config_dock_visible:  resb 1
config_game_mode:     resb 1
config_dev_mode:      resb 1
config_buf:           resb 512

section .text
config_load:
    mov byte [config_dock_visible], 1
    mov byte [config_game_mode], 0
    mov byte [config_dev_mode], 0
    lea rdi, [config_discord_token]
    xor eax, eax
    mov ecx, 32
    rep stosd
    lea rdi, [cfg_path]
    call navinefs_normalize
    mov rdi, rax
    call navinefs_lookup
    cmp eax, -1
    je .defaults
    mov edi, eax
    lea r8, [config_buf]
    mov edx, 512
    call navinefs_read
    test rax, rax
    jz .defaults
    call config_parse
.defaults:
    ret

config_save:
    lea rdi, [cfg_path]
    call navinefs_normalize
    mov r12, rax
    mov rdi, r12
    call navinefs_lookup
    cmp eax, -1
    jne .have
    mov rdi, r12
    xor esi, esi
    call navinefs_register
    mov rdi, r12
    call navinefs_lookup
.have:
    mov ebx, eax
    call config_build
    mov edx, eax
    mov edi, ebx
    lea r8, [config_buf]
    call navinefs_write
    ret

config_build:
    lea rdi, [config_buf]
    lea rsi, [cfg_dock]
    call cfg_put
    movzx eax, byte [config_dock_visible]
    add al, '0'
    mov [rdi], al
    inc rdi
    mov byte [rdi], 10
    inc rdi
    lea rsi, [cfg_game]
    call cfg_put
    movzx eax, byte [config_game_mode]
    add al, '0'
    mov [rdi], al
    inc rdi
    mov byte [rdi], 10
    inc rdi
    lea rsi, [cfg_dev]
    call cfg_put
    movzx eax, byte [config_dev_mode]
    add al, '0'
    mov [rdi], al
    inc rdi
    mov byte [rdi], 10
    inc rdi
    lea rsi, [cfg_token]
    call cfg_put
    lea rsi, [config_discord_token]
.copy_tok:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .done
    inc rsi
    inc rdi
    jmp .copy_tok
.done:
    mov rax, rdi
    sub rax, config_buf
    ret

config_parse:
    lea rsi, [config_buf]
.scan:
    mov al, [rsi]
    test al, al
    jz .out
    lea rdi, [cfg_dock]
    push rsi
    call cfg_match
    pop rsi
    test rax, rax
    jnz .dock
    lea rdi, [cfg_game]
    push rsi
    call cfg_match
    pop rsi
    test rax, rax
    jnz .game
    lea rdi, [cfg_dev]
    push rsi
    call cfg_match
    pop rsi
    test rax, rax
    jnz .dev
    lea rdi, [cfg_token]
    push rsi
    call cfg_match
    pop rsi
    test rax, rax
    jnz .token
    inc rsi
    jmp .scan
.dock:
    add rsi, 5
    movzx eax, byte [rsi]
    sub al, '0'
    mov [config_dock_visible], al
    jmp .scan
.game:
    add rsi, 5
    movzx eax, byte [rsi]
    sub al, '0'
    mov [config_game_mode], al
    jmp .scan
.dev:
    add rsi, 4
    movzx eax, byte [rsi]
    sub al, '0'
    mov [config_dev_mode], al
    jmp .scan
.token:
    add rsi, 7
    lea rdi, [config_discord_token]
.copy:
    mov al, [rsi]
    cmp al, 10
    je .tok_done
    test al, al
    jz .tok_done
    mov [rdi], al
    inc rsi
    inc rdi
    jmp .copy
.tok_done:
    mov byte [rdi], 0
.out:
    ret

cfg_match:
    push rsi
.match:
    mov al, [rdi]
    test al, al
    jz .ok
    cmp al, [rsi]
    jne .no
    inc rdi
    inc rsi
    jmp .match
.ok:
    mov rax, 1
    jmp .done
.no:
    xor rax, rax
.done:
    pop rsi
    ret

cfg_put:
.copy:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .done
    inc rsi
    inc rdi
    jmp .copy
.done:
    ret

section .rodata
cfg_path:   db "/config/navine.cfg", 0
cfg_dock:   db "dock=", 0
cfg_game:   db "game=", 0
cfg_dev:    db "dev=", 0
cfg_token:  db "token=", 0
