; Navine OS - Terminal Emulator

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern font_draw_char
extern font_draw_string
extern font_advance
extern fb_fill_rect
extern fb_width
extern fb_height
extern keyboard_read
extern keyboard_has_data
extern cppapp_launch
extern doom_launch
extern files_toggle
extern desktop_toggle_spotlight
extern desktop_handle_key
extern doom_handle_key
extern apps_handle_key
extern files_handle_key
extern files_visible
extern windows
extern app_open_settings
extern app_open_browser
extern app_open_store
extern app_open_notes
extern app_open_calc
extern app_open_media
extern app_open_monitor
extern app_open_assistant
extern app_open_editor
extern app_open_plugins
extern app_open_studio
extern app_open_discord
extern net_is_ready
extern net_ping_host
extern net_http_get
extern net_https_probe
extern net_get_ip
extern net_gateway_mac
extern e1000_mac
extern browser_navigate
extern navinefs_sync
extern download_default
extern downloads_terminal_list
%endif

global init_terminal
global init_terminal_cli
global terminal_render
global terminal_render_cli
global terminal_handle_input
global terminal_write

section .bss
term_buffer:    resb 4096
term_cursor:    resd 1
term_scroll:    resd 1
term_x:         resd 1
term_y:         resd 1
term_line:      resb 64
term_line_len:  resb 1
term_byte:      resb 2

section .text
init_terminal:
    mov dword [term_cursor], 0
    mov dword [term_scroll], 0
    mov dword [term_x], 164
    mov dword [term_y], 168
    mov byte [term_line_len], 0
    lea rdi, [welcome_msg]
    call terminal_write
    ret

init_terminal_cli:
    mov dword [term_cursor], 0
    mov dword [term_scroll], 0
    mov dword [term_x], 12
    mov dword [term_y], 40
    mov byte [term_line_len], 0
    lea rdi, [cli_welcome_msg]
    call terminal_write
    ret

terminal_write:
    mov rsi, rdi
.loop:
    movzx eax, byte [rsi]
    test al, al
    jz .done
    mov edx, eax
    inc rsi
    mov eax, [term_cursor]
    cmp eax, 4095
    jae .done
    mov [term_buffer + rax], dl
    inc dword [term_cursor]
    cmp dl, 10
    je .newline
    jmp .loop
.newline:
    jmp .loop
.done:
    ret

terminal_handle_input:
    xor r8d, r8d
    call keyboard_has_data
    test rax, rax
    jz .done
    call keyboard_read
    test al, 0x80
    jnz .done
    mov dl, al
    call doom_handle_key
    test eax, eax
    jz .desktop_key
    mov r8d, 1
    jmp .done
.desktop_key:
    call apps_handle_key
    test eax, eax
    jz .desktop_global_key
    mov r8d, 1
    jmp .done
.desktop_global_key:
    call desktop_handle_key
    test eax, eax
    jz .terminal_key
    mov r8d, 1
    jmp .done
.terminal_key:
    mov al, dl
    cmp byte [files_visible], 1
    jne .text_key
    call files_handle_key
    mov r8d, 1
    jmp .done
.text_key:
    cmp al, 28
    je .enter
    cmp al, 14
    je .backspace
    call terminal_scancode_ascii
    test al, al
    jz .done
    movzx edx, al
    mov ecx, [term_cursor]
    cmp ecx, 4095
    jae .done
    mov [term_buffer + rcx], dl
    inc dword [term_cursor]
    cmp byte [term_line_len], 63
    jae .skip_line_store
    movzx ecx, byte [term_line_len]
    lea rbx, [term_line]
    mov [rbx + rcx], dl
    inc byte [term_line_len]
    mov byte [rbx + rcx + 1], 0
.skip_line_store:
    mov r8d, 1
    jmp .done
.enter:
    mov ecx, [term_cursor]
    cmp ecx, 4095
    jae .done
    mov byte [term_buffer + rcx], 10
    inc dword [term_cursor]
    call terminal_run_command
    mov r8d, 1
    jmp .done
.backspace:
    cmp dword [term_cursor], 0
    je .done
    cmp byte [term_line_len], 0
    je .done
    dec dword [term_cursor]
    dec byte [term_line_len]
    movzx ecx, byte [term_line_len]
    lea rbx, [term_line]
    mov byte [rbx + rcx], 0
    mov r8d, 1
    jmp .done
.done:
    mov eax, r8d
    ret

terminal_scancode_ascii:
    cmp al, 0x02
    jb .none
    cmp al, 0x0B
    ja .letters
    movzx eax, al
    mov al, [num_map + rax - 0x02]
    ret
.letters:
    cmp al, 0x10
    jb .punct
    cmp al, 0x32
    ja .punct
    movzx eax, al
    mov al, [key_map + rax - 0x10]
    ret
.punct:
    cmp al, 0x0C
    je .minus
    cmp al, 0x0D
    je .equals
    cmp al, 0x33
    je .comma
    cmp al, 0x34
    je .dot
    cmp al, 0x35
    je .slash
    cmp al, 0x39
    je .space
.none:
    xor eax, eax
    ret
.minus:
    mov al, '-'
    ret
.equals:
    mov al, '='
    ret
.comma:
    mov al, ','
    ret
.dot:
    mov al, '.'
    ret
.slash:
    mov al, '/'
    ret
.space:
    mov al, ' '
    ret

terminal_run_command:
    push rbx
    cmp byte [term_line_len], 0
    je .prompt
    cmp dword [term_line], 0x656D6167
    je .game
    cmp dword [term_line], 0x454D4147
    je .game
    cmp dword [term_line], 0x12311E22
    je .game
    lea rsi, [term_line]
    call terminal_is_game_command
    test eax, eax
    jnz .game
    lea rsi, [term_line]
    lea rdi, [cmd_clear]
    call terminal_streq
    test eax, eax
    jnz .clear
    lea rsi, [term_line]
    lea rdi, [cmd_help]
    call terminal_streq
    test eax, eax
    jnz .help
    lea rsi, [term_line]
    lea rdi, [cmd_apps]
    call terminal_streq
    test eax, eax
    jnz .apps
    lea rsi, [term_line]
    lea rdi, [cmd_game]
    call terminal_streq
    test eax, eax
    jnz .game
    lea rsi, [term_line]
    lea rdi, [cmd_settings]
    call terminal_streq
    test eax, eax
    jnz .settings
    lea rsi, [term_line]
    lea rdi, [cmd_vault]
    call terminal_streq
    test eax, eax
    jnz .vault
    lea rsi, [term_line]
    lea rdi, [cmd_browser]
    call terminal_streq
    test eax, eax
    jnz .browser
    lea rsi, [term_line]
    lea rdi, [cmd_store]
    call terminal_streq
    test eax, eax
    jnz .store
    lea rsi, [term_line]
    lea rdi, [cmd_calc]
    call terminal_streq
    test eax, eax
    jnz .calc
    lea rsi, [term_line]
    lea rdi, [cmd_notes]
    call terminal_streq
    test eax, eax
    jnz .notes
    lea rsi, [term_line]
    lea rdi, [cmd_media]
    call terminal_streq
    test eax, eax
    jnz .media
    lea rsi, [term_line]
    lea rdi, [cmd_monitor]
    call terminal_streq
    test eax, eax
    jnz .monitor
    lea rsi, [term_line]
    lea rdi, [cmd_ai]
    call terminal_streq
    test eax, eax
    jnz .assistant
    lea rsi, [term_line]
    lea rdi, [cmd_editor]
    call terminal_streq
    test eax, eax
    jnz .editor
    lea rsi, [term_line]
    lea rdi, [cmd_plugins]
    call terminal_streq
    test eax, eax
    jnz .plugins
    lea rsi, [term_line]
    lea rdi, [cmd_studio]
    call terminal_streq
    test eax, eax
    jnz .studio
    lea rsi, [term_line]
    lea rdi, [cmd_discord]
    call terminal_streq
    test eax, eax
    jnz .discord
    lea rsi, [term_line]
    lea rdi, [cmd_ping]
    call terminal_streq
    test eax, eax
    jnz .ping
    lea rsi, [term_line]
    lea rdi, [cmd_ifconfig]
    call terminal_streq
    test eax, eax
    jnz .ifconfig
    lea rsi, [term_line]
    lea rdi, [cmd_curl]
    call terminal_streq
    test eax, eax
    jnz .curl
    lea rsi, [term_line]
    lea rdi, [cmd_npkg]
    call terminal_streq
    test eax, eax
    jnz .npkg
    lea rsi, [term_line]
    lea rdi, [cmd_steam]
    call terminal_streq
    test eax, eax
    jnz .steam
    lea rsi, [term_line]
    lea rdi, [cmd_epic]
    call terminal_streq
    test eax, eax
    jnz .epic
    lea rsi, [term_line]
    lea rdi, [cmd_gog]
    call terminal_streq
    test eax, eax
    jnz .gog
    lea rsi, [term_line]
    lea rdi, [cmd_download]
    call terminal_streq
    test eax, eax
    jnz .download
    lea rsi, [term_line]
    lea rdi, [cmd_downloads]
    call terminal_streq
    test eax, eax
    jnz .downloads
    lea rsi, [term_line]
    lea rdi, [cmd_install]
    call terminal_streq
    test eax, eax
    jnz .install
    lea rsi, [term_line]
    lea rdi, [cmd_shutdown]
    call terminal_streq
    test eax, eax
    jnz .shutdown
    lea rdi, [unknown_msg]
    call terminal_write
    jmp .prompt
.clear:
    mov dword [term_cursor], 0
    lea rdi, [welcome_msg]
    call terminal_write
    mov byte [term_line_len], 0
    lea rdi, [term_line]
    mov byte [rdi], 0
    pop rbx
    ret
.help:
    lea rdi, [help_msg]
    call terminal_write
    jmp .prompt
.apps:
    lea rdi, [apps_msg]
    call terminal_write
    jmp .prompt
.game:
    call doom_launch
    lea rdi, [game_msg]
    call terminal_write
    jmp .prompt
.settings:
    call app_open_settings
    lea rdi, [settings_msg]
    call terminal_write
    jmp .prompt
.vault:
    call files_toggle
    lea rdi, [vault_msg]
    call terminal_write
    jmp .prompt
.browser:
    call app_open_browser
    lea rdi, [browser_msg]
    call terminal_write
    jmp .prompt
.store:
    call app_open_store
    lea rdi, [store_msg]
    call terminal_write
    jmp .prompt
.calc:
    call app_open_calc
    lea rdi, [calc_msg]
    call terminal_write
    jmp .prompt
.notes:
    call app_open_notes
    lea rdi, [notes_msg]
    call terminal_write
    jmp .prompt
.media:
    call app_open_media
    lea rdi, [media_msg]
    call terminal_write
    jmp .prompt
.monitor:
    call app_open_monitor
    lea rdi, [monitor_msg]
    call terminal_write
    jmp .prompt
.assistant:
    call app_open_assistant
    lea rdi, [assistant_msg]
    call terminal_write
    jmp .prompt
.editor:
    call app_open_editor
    lea rdi, [editor_msg]
    call terminal_write
    jmp .prompt
.plugins:
    call app_open_plugins
    lea rdi, [plugins_msg]
    call terminal_write
    jmp .prompt
.studio:
    call app_open_studio
    lea rdi, [studio_msg]
    call terminal_write
    jmp .prompt
.discord:
    call app_open_discord
    lea rdi, [discord_msg]
    call terminal_write
    jmp .prompt
.ping:
    mov edi, NET_GATEWAY
    call net_ping_host
    lea rdi, [ping_ok_msg]
    test rax, rax
    jnz .ping_out
    lea rdi, [ping_fail_msg]
.ping_out:
    call terminal_write
    jmp .prompt
.ifconfig:
    call net_is_ready
    test rax, rax
    jz .if_off
    lea rdi, [ifconfig_pfx]
    call terminal_write
    call net_get_ip
    call terminal_write_ipv4
    lea rdi, [ifconfig_sfx]
    call terminal_write
    jmp .prompt
.if_off:
    lea rdi, [ifconfig_off_msg]
    call terminal_write
    jmp .prompt
.curl:
    lea rsi, [term_line + 5]
    call terminal_skip_space
    mov rdi, rsi
    push rsi
    lea rsi, [term_pfx_https]
    call terminal_has_prefix
    pop rdi
    test rax, rax
    jnz .curl_https
    call net_http_get
    jmp .curl_done
.curl_https:
    call net_https_get
.curl_done:
    lea rdi, [curl_msg]
    call terminal_write
    jmp .prompt
.npkg:
    call npkg_list_count
    lea rdi, [npkg_msg]
    call terminal_write
    jmp .prompt
.steam:
    call store_launch_steam
    jmp .prompt
.epic:
    call store_launch_epic
    jmp .prompt
.gog:
    call store_launch_gog
    jmp .prompt
.download:
    call download_default
    lea rdi, [download_msg]
    call terminal_write
    jmp .prompt
.downloads:
    call downloads_terminal_list
    jmp .prompt
.install:
    call npkg_install
    lea rdi, [install_msg]
    call terminal_write
    jmp .prompt
.shutdown:
    lea rdi, [shutdown_msg]
    call terminal_write
    call navinefs_sync
    cli
.poweroff:
    hlt
    jmp .poweroff
.prompt:
    lea rdi, [prompt_msg]
    call terminal_write
    mov byte [term_line_len], 0
    lea rdi, [term_line]
    mov byte [rdi], 0
    pop rbx
    ret

terminal_streq:
    push rbx
.loop:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, 'A'
    jb .left_ready
    cmp al, 'Z'
    ja .left_ready
    add al, 32
.left_ready:
    cmp bl, 'A'
    jb .right_ready
    cmp bl, 'Z'
    ja .right_ready
    add bl, 32
.right_ready:
    cmp al, bl
    jne .no
    test al, al
    jz .yes
    inc rsi
    inc rdi
    jmp .loop
.yes:
    mov eax, 1
    pop rbx
    ret
.no:
    xor eax, eax
    pop rbx
    ret

terminal_is_game_command:
    mov al, [rsi]
    call terminal_tolower
    cmp al, 'g'
    jne .no
    mov al, [rsi + 1]
    call terminal_tolower
    cmp al, 'a'
    jne .no
    mov al, [rsi + 2]
    call terminal_tolower
    cmp al, 'm'
    jne .no
    mov al, [rsi + 3]
    call terminal_tolower
    cmp al, 'e'
    jne .no
    mov al, [rsi + 4]
    test al, al
    jz .yes
    cmp al, ' '
    je .yes
.no:
    xor eax, eax
    ret
.yes:
    mov eax, 1
    ret

terminal_tolower:
    cmp al, 'A'
    jb .done
    cmp al, 'Z'
    ja .done
    add al, 32
.done:
    ret

terminal_has_prefix:
    push rdi
    push rsi
.loop:
    mov al, [rsi]
    test al, al
    jz .yes
    cmp al, [rdi]
    jne .no
    inc rsi
    inc rdi
    jmp .loop
.yes:
    mov rax, 1
    jmp .out
.no:
    xor rax, rax
.out:
    pop rsi
    pop rdi
    ret

terminal_skip_space:
.skip:
    cmp byte [rsi], ' '
    jne .done
    inc rsi
    jmp .skip
.done:
    ret

terminal_write_ipv4:
    push rbx
    mov ebx, eax
    movzx eax, bl
    call terminal_write_u8
    mov al, '.'
    call terminal_write_byte
    movzx eax, bh
    call terminal_write_u8
    mov al, '.'
    call terminal_write_byte
    mov eax, ebx
    shr eax, 16
    movzx eax, al
    call terminal_write_u8
    mov al, '.'
    call terminal_write_byte
    mov eax, ebx
    shr eax, 24
    movzx eax, al
    call terminal_write_u8
    pop rbx
    ret

terminal_write_u8:
    push rbx
    push rcx
    push rdx
    movzx ebx, al
    cmp ebx, 100
    jb .lt100
    mov eax, ebx
    xor edx, edx
    mov ecx, 100
    div ecx
    add al, '0'
    call terminal_write_byte
    mov ebx, edx
    mov eax, ebx
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, '0'
    call terminal_write_byte
    mov al, dl
    add al, '0'
    call terminal_write_byte
    jmp .done
.lt100:
    cmp ebx, 10
    jb .lt10
    mov eax, ebx
    xor edx, edx
    mov ecx, 10
    div ecx
    add al, '0'
    call terminal_write_byte
    mov al, dl
    add al, '0'
    call terminal_write_byte
    jmp .done
.lt10:
    mov al, bl
    add al, '0'
    call terminal_write_byte
.done:
    pop rdx
    pop rcx
    pop rbx
    ret

terminal_write_byte:
    push rdi
    mov [term_byte], al
    lea rdi, [term_byte]
    mov byte [term_byte + 1], 0
    call terminal_write
    pop rdi
    ret

terminal_render:
    cmp byte [windows + 20], 0
    je .hidden
    push rbx
    push r12
    push r13
    mov edi, [windows]
    add edi, 24
    mov esi, [windows + 4]
    add esi, 54
    mov r12d, [windows]
    add r12d, [windows + 8]
    sub r12d, 24
    mov r13d, [windows + 4]
    add r13d, [windows + 12]
    sub r13d, 22
    mov [term_x], edi
    mov [term_y], esi
    xor ebx, ebx
.loop:
    cmp esi, r13d
    jge .done
    mov ecx, [term_cursor]
    cmp ebx, ecx
    jge .done
    movzx edx, byte [term_buffer + rbx]
    cmp dl, 10
    je .newline
    mov ecx, COLOR_WHITE
    push rbx
    push rcx
    push rdi
    push rsi
    call font_draw_char
    pop rsi
    pop rdi
    pop rcx
    pop rbx
    add edi, 9
    cmp edi, r12d
    jl .same_line
    mov edi, [term_x]
    add esi, 16
.same_line:
    inc ebx
    jmp .loop
.newline:
    mov edi, [term_x]
    add esi, 16
    inc ebx
    jmp .loop
.done:
    mov edi, edi
    mov esi, esi
    mov edx, 2
    mov ecx, 14
    mov r8d, 0xFF65D6FF
    call fb_fill_rect
    pop r13
    pop r12
    pop rbx
.hidden:
    ret

terminal_render_cli:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov edi, 0
    mov esi, 0
    mov edx, [fb_width]
    mov ecx, 28
    mov r8d, 0xFF121824
    call fb_fill_rect
    mov edi, 12
    mov esi, 6
    lea rdx, [cli_title_msg]
    mov ecx, 0xFF65D6FF
    call font_draw_string
    mov edi, 8
    mov esi, 32
    mov edx, [fb_width]
    sub edx, 16
    mov ecx, 1
    mov r8d, 0x8865D6FF
    call fb_fill_rect
    mov edi, [term_x]
    mov esi, [term_y]
    mov r12d, [fb_width]
    sub r12d, 12
    mov r13d, [fb_height]
    sub r13d, 12
    xor ebx, ebx
.loop:
    cmp esi, r13d
    jge .cursor
    mov ecx, [term_cursor]
    cmp ebx, ecx
    jge .cursor
    movzx edx, byte [term_buffer + rbx]
    cmp dl, 10
    je .newline
    mov ecx, COLOR_WHITE
    push rbx
    push rdi
    push rsi
    call font_draw_char
    pop rsi
    pop rdi
    pop rbx
    call font_advance
    add edi, eax
    cmp edi, r12d
    jl .same
    mov edi, [term_x]
    add esi, 16
.same:
    inc ebx
    jmp .loop
.newline:
    mov edi, [term_x]
    add esi, 16
    inc ebx
    jmp .loop
.cursor:
    mov edx, 2
    mov ecx, 14
    mov r8d, 0xFF65D6FF
    call fb_fill_rect
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

section .rodata
cli_title_msg: db "Navine OS CLI", 0
cli_welcome_msg:
    db "Navine OS CLI Edition", 10
    db "Type help for commands.", 10, 10
    db "navine> ", 0
welcome_msg: db "Navine OS Console ready", 10, "navine> ", 0
system_return_msg: db 10, "Returned from Navine Control", 10, "navine> ", 0
prompt_msg: db "navine> ", 0
cmd_clear: db "clear", 0
cmd_help: db "help", 0
cmd_apps: db "apps", 0
cmd_game: db "game", 0
cmd_settings: db "settings", 0
cmd_vault: db "vault", 0
cmd_browser: db "browser", 0
cmd_store: db "store", 0
cmd_calc: db "calc", 0
cmd_notes: db "notes", 0
cmd_media: db "media", 0
cmd_monitor: db "monitor", 0
cmd_ai: db "ai", 0
cmd_editor: db "editor", 0
cmd_plugins: db "plugins", 0
cmd_studio: db "studio", 0
cmd_discord: db "discord", 0
cmd_ping: db "ping", 0
cmd_ifconfig: db "ifconfig", 0
cmd_curl: db "curl", 0
cmd_npkg: db "npkg", 0
cmd_steam: db "steam", 0
cmd_epic: db "epic", 0
cmd_gog: db "gog", 0
cmd_download: db "download", 0
cmd_downloads: db "downloads", 0
cmd_install: db "install", 0
cmd_shutdown: db "shutdown", 0
help_msg: db "Commands: help clear ping ifconfig curl download downloads apps game settings vault browser store calc notes media monitor ai editor plugins studio discord npkg install shutdown", 10, "Note: steam/epic/gog/npkg are placeholders; HTTPS decrypt is incomplete.", 10, 0
apps_msg: db "Apps: Settings, Vault, Console, Browser, Store, Notes, Calc, Game, Media, Monitor, Assistant, Editor, Plugins, Studio, Discord", 10, 0
game_msg: db "Game launched.", 10, 0
settings_msg: db "Settings center opened.", 10, 0
vault_msg: db "Vault toggled.", 10, 0
browser_msg: db "Browser opened (local pages + basic HTTP).", 10, 0
store_msg: db "Store UI opened (catalog is local/demo).", 10, 0
calc_msg: db "Calculator opened.", 10, 0
notes_msg: db "Notes opened.", 10, 0
media_msg: db "Media opened.", 10, 0
monitor_msg: db "System monitor opened.", 10, 0
assistant_msg: db "Assistant opened.", 10, 0
editor_msg: db "Editor opened.", 10, 0
plugins_msg: db "Plugin manager opened.", 10, 0
studio_msg: db "Developer Studio opened.", 10, 0
discord_msg: db "Discord UI opened (gateway incomplete).", 10, 0
ping_ok_msg: db "ping: reply received", 10, 0
ping_fail_msg: db "ping: no reply", 10, 0
ifconfig_pfx: db "e1000 up  ip ", 0
ifconfig_sfx: db "  gateway 10.0.2.2  dns 10.0.2.3", 10, 0
ifconfig_off_msg: db "Network: no NIC", 10, 0
curl_msg: db "curl: request finished (check downloads; TLS may be incomplete)", 10, 0
npkg_msg: db "npkg: placeholder package list (not a real package manager yet)", 10, 0
term_pfx_https: db "https://", 0
download_msg: db "Downloading grid-pack... saved to NavineFS. See nav://downloads", 10, 0
install_msg:  db "Package install is a demo (npkg is not a real package manager yet).", 10, 0
shutdown_msg: db "Syncing NavineFS and shutting down...", 10, 0
unknown_msg: db "Command not found. Type help.", 10, 0
num_map: db "1234567890"
key_map:
    db "qwertyuiop", 0, 0, 0, 0, "asdfghjkl", 0, 0, 0, 0, 0, "zxcvbnm"
