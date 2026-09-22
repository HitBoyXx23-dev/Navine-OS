; Navine OS - Native lightweight application panels

[BITS 64]

%include "constants.inc"

global init_simpleapps
global apps_render
global apps_handle_mouse
global apps_handle_key
global app_open_settings
global app_open_browser
global app_open_store
global app_open_notes
global app_open_calc
global app_open_media
global app_open_monitor
global app_open_assistant
global app_open_editor
global app_open_plugins
global app_open_studio

extern fb_fill_rect
extern font_draw_string
extern mouse_x
extern mouse_y
extern mouse_buttons
extern doom_launch

section .bss
app_active:      resb 1
app_type:        resb 1
app_mouse_last:  resb 1
app_input_len:   resb 1
app_input:       resb 80
notes_len:       resb 1
notes_buf:       resb 160
calc_a:          resd 1
calc_b:          resd 1
calc_mode:       resb 1
calc_result:     resb 8
settings_dyn1:   resb 80
settings_dyn2:   resb 80
settings_dyn3:   resb 80
settings_dyn4:   resb 80
monitor_dyn1:    resb 80
monitor_dyn2:    resb 80
monitor_dyn3:    resb 80

section .text
init_simpleapps:
    mov byte [app_active], 0
    mov byte [app_mouse_last], 0
    mov byte [app_input_len], 0
    mov byte [notes_len], 0
    mov byte [calc_mode], 0
    mov dword [calc_a], 0
    mov dword [calc_b], 0
    lea rdi, [app_input]
    xor eax, eax
    mov ecx, 80
    rep stosb
    lea rdi, [notes_buf]
    xor eax, eax
    mov ecx, 160
    rep stosb
    lea rdi, [calc_result]
    xor eax, eax
    mov ecx, 8
    rep stosb
    call browser_init
    ret

app_open_settings:
    mov byte [app_type], 1
    jmp app_open_common
app_open_browser:
    mov byte [app_type], 2
    call browser_go_home
    jmp app_open_common
app_open_store:
    mov byte [app_type], 3
    jmp app_open_common
app_open_notes:
    mov byte [app_type], 4
    jmp app_open_common
app_open_calc:
    mov byte [app_type], 5
    mov dword [calc_a], 0
    mov dword [calc_b], 0
    mov byte [calc_mode], 0
    lea rdi, [calc_result]
    xor eax, eax
    mov ecx, 8
    rep stosb
    jmp app_open_common
app_open_media:
    mov byte [app_type], 6
    jmp app_open_common
app_open_monitor:
    mov byte [app_type], 7
    jmp app_open_common
app_open_assistant:
    mov byte [app_type], 8
    jmp app_open_common
app_open_editor:
    mov byte [app_type], 9
    jmp app_open_common
app_open_plugins:
    mov byte [app_type], 10
    jmp app_open_common
app_open_studio:
    mov byte [app_type], 11
app_open_common:
    mov byte [app_active], 1
    mov byte [app_input_len], 0
    lea rdi, [app_input]
    xor eax, eax
    mov ecx, 80
    rep stosb
    ret

apps_render:
    cmp byte [app_active], 1
    jne .done
    mov edi, 640
    mov esi, 150
    mov edx, 760
    mov ecx, 500
    mov r8d, 0xBB000000
    call fb_fill_rect
    mov edi, 620
    mov esi, 132
    mov edx, 760
    mov ecx, 500
    mov r8d, 0xF0121824
    call fb_fill_rect
    mov edi, 620
    mov esi, 132
    mov edx, 760
    mov ecx, 44
    mov r8d, 0xFF222B3A
    call fb_fill_rect
    mov edi, 637
    mov esi, 148
    lea rdx, [app_close]
    mov ecx, 0xFFFF5F57
    call font_draw_string
    mov edi, 675
    mov esi, 148
    call app_title_ptr
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 620
    mov esi, 176
    mov edx, 760
    mov ecx, 2
    mov r8d, 0xFF65D6FF
    call fb_fill_rect
    call app_body_render
.done:
    ret

app_body_render:
    movzx eax, byte [app_type]
    cmp al, 1
    je render_settings
    cmp al, 2
    je render_browser
    cmp al, 3
    je render_store
    cmp al, 4
    je render_notes
    cmp al, 5
    je render_calc
    cmp al, 6
    je render_media
    cmp al, 7
    je render_monitor
    cmp al, 8
    je render_assistant
    cmp al, 9
    je render_editor
    cmp al, 10
    je render_plugins
    cmp al, 11
    je render_studio
    ret

render_settings:
    call settings_fill
    lea rdx, [settings_dyn1]
    call draw_line1
    lea rdx, [settings_dyn2]
    call draw_line2
    lea rdx, [settings_dyn3]
    call draw_line3
    lea rdx, [settings_dyn4]
    call draw_line4
    ret
render_browser:
    lea rdi, [app_input]
    call browser_render_panel
    ret
render_store:
    lea rdx, [store_l1]
    call draw_line1
    lea rdx, [store_l2]
    call draw_line2
    lea rdx, [store_l3]
    call draw_line3
    lea rdx, [store_l4]
    call draw_line4
    ret
render_notes:
    lea rdx, [notes_l1]
    call draw_line1
    lea rdx, [notes_buf]
    call draw_input
    lea rdx, [notes_l2]
    call draw_line5
    ret
render_calc:
    lea rdx, [calc_l1]
    call draw_line1
    lea rdx, [app_input]
    call draw_input
    lea rdx, [calc_l2]
    call draw_line4
    lea rdx, [calc_result]
    call draw_line5
    ret
render_media:
    lea rdx, [media_l1]
    call draw_line1
    lea rdx, [media_l2]
    call draw_line2
    lea rdx, [media_l3]
    call draw_line3
    ret
render_monitor:
    call monitor_fill
    lea rdx, [monitor_dyn1]
    call draw_line1
    lea rdx, [monitor_dyn2]
    call draw_line2
    lea rdx, [monitor_dyn3]
    call draw_line3
    ret
render_assistant:
    lea rdx, [assistant_l1]
    call draw_line1
    lea rdx, [assistant_l2]
    call draw_line2
    lea rdx, [app_input]
    call draw_input
    ret
render_editor:
    lea rdx, [editor_l1]
    call draw_line1
    lea rdx, [notes_buf]
    call draw_input
    lea rdx, [editor_l2]
    call draw_line5
    ret
render_plugins:
    lea rdx, [plugins_l1]
    call draw_line1
    lea rdx, [plugins_l2]
    call draw_line2
    lea rdx, [plugins_l3]
    call draw_line3
    ret
render_studio:
    lea rdx, [studio_l1]
    call draw_line1
    lea rdx, [studio_l2]
    call draw_line2
    lea rdx, [studio_l3]
    call draw_line3
    ret

draw_line1:
    mov edi, 650
    mov esi, 210
    mov ecx, COLOR_WHITE
    call font_draw_string
    ret
draw_line2:
    mov edi, 650
    mov esi, 250
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    ret
draw_line3:
    mov edi, 650
    mov esi, 290
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    ret
draw_line4:
    mov edi, 650
    mov esi, 330
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    ret
draw_line5:
    mov edi, 650
    mov esi, 410
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    ret
draw_input:
    push rdx
    mov edi, 650
    mov esi, 330
    mov edx, 650
    mov ecx, 46
    mov r8d, 0xFF0D1117
    call fb_fill_rect
    pop rdx
    mov edi, 668
    mov esi, 346
    mov ecx, COLOR_WHITE
    call font_draw_string
    ret

apps_handle_mouse:
    xor eax, eax
    cmp byte [app_active], 1
    jne .done
    mov al, [mouse_buttons]
    mov bl, [app_mouse_last]
    mov [app_mouse_last], al
    test al, 1
    jz .done
    test bl, 1
    jnz .done
    mov eax, [mouse_x]
    cmp eax, 620
    jl .done
    cmp eax, 1380
    jg .done
    mov eax, [mouse_y]
    cmp eax, 132
    jl .done
    cmp eax, 632
    jg .done
    mov r9d, 1
    mov eax, [mouse_x]
    cmp eax, 632
    jl .consume
    cmp eax, 660
    jg .maybe_action
    mov eax, [mouse_y]
    cmp eax, 140
    jl .consume
    cmp eax, 172
    jg .consume
    mov byte [app_active], 0
    jmp .consume
.maybe_action:
    cmp byte [app_type], 3
    jne .consume
    call doom_launch
.consume:
    mov eax, r9d
.done:
    ret

apps_handle_key:
    cmp byte [app_active], 1
    jne .no
    cmp dl, 0x01
    jne .not_esc
    mov byte [app_active], 0
    mov eax, 1
    ret
.not_esc:
    cmp byte [app_type], 4
    je .notes_key
    cmp byte [app_type], 9
    je .notes_key
    cmp byte [app_type], 2
    je .browser_key
    cmp byte [app_type], 5
    je .calc_key
    cmp byte [app_type], 8
    je .input_key
    mov eax, 1
    ret
.notes_key:
    call app_scancode_ascii
    test al, al
    jz .special
    movzx ecx, byte [notes_len]
    cmp ecx, 159
    jae .yes
    lea rdi, [notes_buf]
    mov [rdi + rcx], al
    inc byte [notes_len]
    mov byte [rdi + rcx + 1], 0
    jmp .yes
.special:
    cmp dl, 0x0E
    jne .yes
    cmp byte [notes_len], 0
    je .yes
    dec byte [notes_len]
    movzx ecx, byte [notes_len]
    lea rdi, [notes_buf]
    mov byte [rdi + rcx], 0
    jmp .yes
.input_key:
    call app_input_key
    jmp .yes
.browser_key:
    cmp dl, 0x1C
    je .browser_go
    call app_input_key
    jmp .yes
.browser_go:
    lea rdi, [app_input]
    call browser_navigate
    jmp .yes
.calc_key:
    cmp dl, 0x1C
    je .calc_enter
    call app_input_key
    jmp .yes
.calc_enter:
    call calc_compute
    jmp .yes
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

app_input_key:
    cmp dl, 0x0E
    je .back
    call app_scancode_ascii
    test al, al
    jz .done
    movzx ecx, byte [app_input_len]
    cmp ecx, 79
    jae .done
    lea rdi, [app_input]
    mov [rdi + rcx], al
    inc byte [app_input_len]
    mov byte [rdi + rcx + 1], 0
    ret
.back:
    cmp byte [app_input_len], 0
    je .done
    dec byte [app_input_len]
    movzx ecx, byte [app_input_len]
    lea rdi, [app_input]
    mov byte [rdi + rcx], 0
.done:
    ret

calc_compute:
    xor eax, eax
    xor ebx, ebx
    xor edx, edx
    lea rsi, [app_input]
.loop:
    movzx ecx, byte [rsi]
    test cl, cl
    jz .finish
    cmp cl, '+'
    je .plus
    cmp cl, '0'
    jb .next
    cmp cl, '9'
    ja .next
    sub cl, '0'
    cmp byte [calc_mode], 0
    jne .add_b
    imul eax, eax, 10
    add eax, ecx
    jmp .next
.add_b:
    imul ebx, ebx, 10
    add ebx, ecx
    jmp .next
.plus:
    mov byte [calc_mode], 1
.next:
    inc rsi
    jmp .loop
.finish:
    add eax, ebx
    call calc_write_result
    ret

calc_write_result:
    lea rdi, [calc_result]
    mov byte [rdi], '='
    inc rdi
    cmp eax, 0
    jne .nonzero
    mov byte [rdi], '0'
    mov byte [rdi + 1], 0
    ret
.nonzero:
    xor ecx, ecx
.digits:
    xor edx, edx
    mov ebx, 10
    div ebx
    add dl, '0'
    push rdx
    inc ecx
    test eax, eax
    jnz .digits
.write:
    pop rax
    mov [rdi], al
    inc rdi
    loop .write
    mov byte [rdi], 0
    ret

app_scancode_ascii:
    mov al, dl
    cmp al, 0x02
    jb .none
    cmp al, 0x0B
    ja .letters
    movzx eax, al
    mov al, [app_num_map + rax - 0x02]
    ret
.letters:
    cmp al, 0x10
    jb .punct
    cmp al, 0x32
    ja .punct
    movzx eax, al
    mov al, [app_key_map + rax - 0x10]
    ret
.punct:
    cmp al, 0x0C
    je .minus
    cmp al, 0x0D
    je .plus
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
.plus:
    mov al, '+'
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

settings_fill:
    lea rdi, [settings_dyn1]
    lea rsi, [settings_l1]
    call sa_copy
    lea rdi, [settings_dyn2]
    lea rsi, [settings_l2]
    call sa_copy
    lea rdi, [settings_dyn3]
    lea rsi, [st_net_prefix]
    call sa_copy
    call net_is_ready
    test rax, rax
    jz .net_no
    lea rsi, [st_net_up]
    jmp .net_put
.net_no:
    lea rsi, [st_net_down]
.net_put:
    call sa_append
    lea rdi, [settings_dyn4]
    lea rsi, [st_token_prefix]
    call sa_copy
    lea rsi, [config_discord_token]
    call sa_append
    ret

monitor_fill:
    lea rdi, [monitor_dyn1]
    lea rsi, [mon_tick_prefix]
    call sa_copy
    mov rax, [pit_ticks]
    call sa_append_u64
    lea rdi, [monitor_dyn2]
    lea rsi, [mon_heap_prefix]
    call sa_copy
    call heap_free_bytes
    call sa_append_u64
    lea rdi, [monitor_dyn3]
    lea rsi, [mon_net_prefix]
    call sa_copy
    call net_is_ready
    test rax, rax
    jz .mno
    lea rsi, [st_net_up]
    jmp .mput
.mno:
    lea rsi, [st_net_down]
.mput:
    call sa_append
    ret

sa_copy:
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

sa_append:
.seek:
    cmp byte [rdi], 0
    je .put
    inc rdi
    jmp .seek
.put:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .out
    inc rsi
    inc rdi
    jmp .put
.out:
    ret

sa_append_u64:
    push rbx
    mov rbx, rax
    mov ecx, 20
    lea rdi, [sa_num_buf + 19]
    mov byte [rdi], 0
.digit:
    xor edx, edx
    mov eax, ebx
    mov esi, 10
    div esi
    add dl, '0'
    dec rdi
    mov [rdi], dl
    mov ebx, eax
    test ebx, ebx
    jnz .digit
    mov rsi, rdi
    call sa_append
    pop rbx
    ret

sa_num_buf: times 20 db 0

app_title_ptr:
    movzx eax, byte [app_type]
    cmp al, 1
    je .settings
    cmp al, 2
    je .browser
    cmp al, 3
    je .store
    cmp al, 4
    je .notes
    cmp al, 5
    je .calc
    cmp al, 6
    je .media
    cmp al, 7
    je .monitor
    cmp al, 8
    je .assistant
    cmp al, 9
    je .editor
    cmp al, 10
    je .plugins
    lea rdx, [title_studio]
    ret
.settings:
    lea rdx, [title_settings]
    ret
.browser:
    lea rdx, [title_browser]
    ret
.store:
    lea rdx, [title_store]
    ret
.notes:
    lea rdx, [title_notes]
    ret
.calc:
    lea rdx, [title_calc]
    ret
.media:
    lea rdx, [title_media]
    ret
.monitor:
    lea rdx, [title_monitor]
    ret
.assistant:
    lea rdx, [title_assistant]
    ret
.editor:
    lea rdx, [title_editor]
    ret
.plugins:
    lea rdx, [title_plugins]
    ret

section .rodata
app_close: db "X", 0
title_settings: db "Navine Settings", 0
title_browser: db "Navine Browser", 0
title_store: db "Navine Store", 0
title_notes: db "Navine Notes", 0
title_calc: db "Navine Calculator", 0
title_media: db "Navine Media", 0
title_monitor: db "System Monitor", 0
title_assistant: db "Navine Assistant", 0
title_editor: db "Text Editor", 0
title_plugins: db "Plugin Manager", 0
title_studio: db "Plugin Developer Studio", 0
settings_l1: db "Appearance: wallpaper active, dark glass theme", 0
settings_l2: db "Input: keyboard, PS/2 mouse, focused windows", 0
settings_l3: db "Network: e1000 NAT  DHCP  ping curl ifconfig in terminal", 0
settings_l4: db "Discord token: set in config/navine.cfg", 0
st_net_prefix: db "Network: ", 0
st_net_up: db "e1000 ready (DHCP/NAT)", 0
st_net_down: db "offline", 0
st_token_prefix: db "Token: ", 0
mon_tick_prefix: db "Timer ticks: ", 0
mon_heap_prefix: db "Heap free bytes: ", 0
mon_net_prefix: db "NIC status: ", 0
browser_l1: db "Enter address or search term:", 0
browser_l2: db "Network service is staged inside Navine OS.", 0
browser_l3: db "Demo page: local://navine/home", 0
store_l1: db "Game stores (external launchers)", 0
store_l2: db "Steam / Epic / GOG wrappers ready", 0
store_l3: db "Navine Grid built-in game installed", 0
store_l4: db "Type: steam epic gog in terminal", 0
notes_l1: db "Notes save in memory for this session:", 0
notes_l2: db "Type to edit. Esc closes.", 0
calc_l1: db "Calculator: type A+B then Enter", 0
calc_l2: db "Result:", 0
media_l1: db "Media Player", 0
media_l2: db "Playlist: Welcome Tone, Focus Loop, Night Theme", 0
media_l3: db "Playback engine staged. UI controls ready.", 0
monitor_l1: db "Game library: Navine Grid + Vulkan stub", 0
monitor_l2: db "Network: e1000 probe   ACPI battery: 85%", 0
monitor_l3: db "Game Mode FPS overlay when G is pressed", 0
assistant_l1: db "Ask Navine Assistant:", 0
assistant_l2: db "Type a prompt. Local response engine staged.", 0
editor_l1: db "Editor buffer:", 0
editor_l2: db "Shares session text with Notes.", 0
plugins_l1: db "Plugin Manager", 0
plugins_l2: db "Enabled: Theme Hooks, Workspace Widgets", 0
plugins_l3: db "Permissions: UI, notifications, file metadata", 0
studio_l1: db "Developer Studio", 0
studio_l2: db "Template: Widget, Theme, Command, Automation", 0
studio_l3: db "Tools: manifest preview, package, publish", 0
app_num_map: db "1234567890"
app_key_map:
    db "qwertyuiop", 0, 0, 0, 0, "asdfghjkl", 0, 0, 0, 0, 0, "zxcvbnm"
