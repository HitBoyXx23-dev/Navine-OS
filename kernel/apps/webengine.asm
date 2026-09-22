; Navine OS - Browser engine and download manager

[BITS 64]

%include "constants.inc"

%ifndef NAVINE_LINK_BUILD
extern fb_fill_rect
extern font_draw_string
extern navinefs_write
extern navinefs_register
extern navinefs_lookup
extern navinefs_mounted
extern terminal_write
extern net_http_get
extern net_https_probe
extern net_fetch_title
extern net_fetch_lines
extern net_fetch_count
extern net_is_ready
%endif

global browser_init
global browser_navigate
global browser_render_panel
global browser_go_home
global download_start
global download_default
global downloads_count
global downloads_terminal_list

section .bss
dl_count:        resd 1
dl_repo_index:   resd 16
dl_scratch:      resb 64

section .data
browser_title_ptr:  dq page_home_title
browser_lines_ptr:  dq page_home_lines
browser_status_ptr: dq status_ready
browser_is_downloads: db 0

section .text
browser_init:
    mov dword [dl_count], 0
    call browser_restore_downloads
    call browser_go_home
    ret

browser_restore_downloads:
    cmp byte [navinefs_mounted], 0
    je .out
    xor ebx, ebx
.loop:
    lea rax, [repo_table]
    mov ecx, ebx
    imul ecx, 8
    add rax, rcx
    mov rax, [rax]
    test rax, rax
    je .out
    mov rdi, rax
    call navinefs_lookup
    cmp eax, -1
    je .next
    mov ecx, [dl_count]
    cmp ecx, 16
    jae .out
    lea rdx, [dl_repo_index]
    mov esi, ecx
    shl rsi, 2
    add rdx, rsi
    mov [rdx], ebx
    inc dword [dl_count]
.next:
    inc ebx
    jmp .loop
.out:
    ret

browser_go_home:
    lea rax, [page_home_title]
    mov [browser_title_ptr], rax
    lea rax, [page_home_lines]
    mov [browser_lines_ptr], rax
    lea rax, [status_ready]
    mov [browser_status_ptr], rax
    mov byte [browser_is_downloads], 0
    ret

; rdi = address string
browser_navigate:
    push rbx
    push r12
    mov r12, rdi
    mov byte [browser_is_downloads], 0
    mov rdi, r12
    lea rsi, [pfx_download]
    call str_starts
    test rax, rax
    jnz .download
    mov rdi, r12
    lea rsi, [pfx_http]
    call str_starts
    test rax, rax
    jnz .remote_http
    mov rdi, r12
    lea rsi, [pfx_https]
    call str_starts
    test rax, rax
    jnz .remote_https
    mov rdi, r12
    call strip_scheme
    mov r12, rax
    lea rbx, [page_table]
.loop:
    mov rax, [rbx]
    test rax, rax
    jz .notfound
    mov rdi, r12
    mov rsi, [rbx]
    call str_ieq
    test rax, rax
    jnz .match
    add rbx, 24
    jmp .loop
.match:
    mov rax, [rbx + 8]
    mov [browser_title_ptr], rax
    mov rax, [rbx + 16]
    mov [browser_lines_ptr], rax
    lea rax, [status_loaded]
    mov [browser_status_ptr], rax
    mov rdi, r12
    lea rsi, [url_downloads]
    call str_ieq
    test rax, rax
    jz .out
    mov byte [browser_is_downloads], 1
    jmp .out
.remote_http:
    call net_is_ready
    test rax, rax
    jz .net_off
    mov rdi, r12
    call net_http_get
    test rax, rax
    jz .net_fail
    lea rax, [net_fetch_title]
    mov [browser_title_ptr], rax
    lea rax, [net_fetch_lines]
    mov [browser_lines_ptr], rax
    lea rax, [status_remote]
    mov [browser_status_ptr], rax
    jmp .out
.remote_https:
    call net_is_ready
    test rax, rax
    jz .net_off
    mov rdi, r12
    call net_https_get
    test rax, rax
    jz .net_fail
    lea rax, [net_fetch_title]
    mov [browser_title_ptr], rax
    lea rax, [net_fetch_lines]
    mov [browser_lines_ptr], rax
    lea rax, [status_remote]
    mov [browser_status_ptr], rax
    jmp .out
.net_off:
    lea rax, [page_net_off_title]
    mov [browser_title_ptr], rax
    lea rax, [page_net_off_lines]
    mov [browser_lines_ptr], rax
    lea rax, [status_notfound]
    mov [browser_status_ptr], rax
    jmp .out
.net_fail:
    lea rax, [net_fetch_title]
    mov [browser_title_ptr], rax
    lea rax, [net_fetch_lines]
    mov [browser_lines_ptr], rax
    lea rax, [status_notfound]
    mov [browser_status_ptr], rax
    jmp .out
.download:
    lea rdi, [r12 + 9]
    call download_start
    lea rax, [page_dl_title]
    mov [browser_title_ptr], rax
    lea rax, [page_dl_lines]
    mov [browser_lines_ptr], rax
    mov byte [browser_is_downloads], 1
    test rax, rax
    lea rax, [status_downloaded]
    mov [browser_status_ptr], rax
    jmp .out
.notfound:
    lea rax, [page_search_title]
    mov [browser_title_ptr], rax
    lea rax, [page_search_lines]
    mov [browser_lines_ptr], rax
    lea rax, [status_notfound]
    mov [browser_status_ptr], rax
.out:
    pop r12
    pop rbx
    ret

; rdi = input buffer pointer (address bar text)
browser_render_panel:
    push rbx
    mov rbx, rdi
    mov edi, 650
    mov esi, 202
    lea rdx, [label_address]
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 650
    mov esi, 222
    mov edx, 700
    mov ecx, 30
    mov r8d, 0xFF0D1117
    call fb_fill_rect
    mov edi, 660
    mov esi, 230
    mov rdx, rbx
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 650
    mov esi, 268
    mov rdx, [browser_title_ptr]
    mov ecx, 0xFF65D6FF
    call font_draw_string
    cmp byte [browser_is_downloads], 1
    je .downloads
    mov rbx, [browser_lines_ptr]
    mov r9d, 300
.line:
    mov rax, [rbx]
    test rax, rax
    jz .status
    mov edi, 650
    mov esi, r9d
    mov rdx, rax
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    add rbx, 8
    add r9d, 26
    jmp .line
.downloads:
    call downloads_render_lines
.status:
    mov edi, 650
    mov esi, 600
    mov rdx, [browser_status_ptr]
    mov ecx, 0xFF7CFF9A
    call font_draw_string
    pop rbx
    ret

downloads_render_lines:
    push rbx
    push r12
    push r13
    xor r12d, r12d
    mov r13d, 300
    cmp dword [dl_count], 0
    jne .loop
    mov edi, 650
    mov esi, 300
    lea rdx, [dl_empty]
    mov ecx, 0xFFB8D7F0
    call font_draw_string
    jmp .out
.loop:
    cmp r12d, [dl_count]
    jge .out
    mov eax, r12d
    imul eax, 4
    lea rbx, [dl_repo_index]
    add rbx, rax
    mov edi, [rbx]
    call repo_name_ptr
    mov edi, 650
    mov esi, r13d
    mov rdx, rax
    mov ecx, COLOR_WHITE
    call font_draw_string
    mov edi, 900
    mov esi, r13d
    lea rdx, [dl_done]
    mov ecx, 0xFF7CFF9A
    call font_draw_string
    inc r12d
    add r13d, 26
    jmp .loop
.out:
    pop r13
    pop r12
    pop rbx
    ret

; rdi = package name string
download_start:
    push rbx
    push r12
    mov r12, rdi
    xor ebx, ebx
.find:
    lea rax, [repo_table]
    mov ecx, ebx
    imul ecx, 8
    add rax, rcx
    mov rax, [rax]
    test rax, rax
    jz .fail
    mov rdi, r12
    mov rsi, rax
    call str_ieq
    test rax, rax
    jnz .found
    inc ebx
    jmp .find
.found:
    mov eax, [dl_count]
    cmp eax, 16
    jae .fail
    lea rcx, [dl_repo_index]
    mov edx, eax
    imul edx, 4
    add rcx, rdx
    mov [rcx], ebx
    mov edi, eax
    call repo_name_ptr
    mov rsi, rax
    lea rdi, [dl_scratch]
    call copy_str
    mov edi, [dl_count]
    lea rax, [dl_scratch]
    mov r8, rax
    mov edx, 64
    call navinefs_write
    test rax, rax
    jz .fail
    mov esi, edi
    lea rdi, [dl_scratch]
    call navinefs_register
    inc dword [dl_count]
    mov rax, 1
    jmp .out
.fail:
    xor rax, rax
.out:
    pop r12
    pop rbx
    ret

download_default:
    lea rdi, [repo_grid]
    call download_start
    ret

downloads_count:
    mov eax, [dl_count]
    ret

downloads_terminal_list:
    lea rdi, [dl_term_msg]
    call terminal_write
    ret

; edi = repo index -> rax = name ptr
repo_name_ptr:
    lea rax, [repo_table]
    mov ecx, edi
    imul ecx, 8
    add rax, rcx
    mov rax, [rax]
    test rax, rax
    jnz .ok
    lea rax, [repo_unknown]
.ok:
    ret

; rdi = str, rsi = prefix -> rax=1 if str starts with prefix
str_starts:
    push rsi
    push rdi
.c:
    movzx eax, byte [rsi]
    test al, al
    jz .yes
    movzx ecx, byte [rdi]
    cmp al, cl
    jne .no
    inc rsi
    inc rdi
    jmp .c
.yes:
    mov rax, 1
    jmp .out
.no:
    xor rax, rax
.out:
    pop rdi
    pop rsi
    ret

; rdi = str -> rax = str past "nav://" if present
strip_scheme:
    push rdi
    lea rsi, [pfx_nav]
    call str_starts
    pop rdi
    test rax, rax
    jz .plain
    add rdi, 6
.plain:
    mov rax, rdi
    ret

; rdi, rsi case-insensitive equal -> rax=1/0
str_ieq:
    push rsi
    push rdi
.c:
    movzx eax, byte [rdi]
    movzx ecx, byte [rsi]
    cmp al, 'A'
    jb .l1
    cmp al, 'Z'
    ja .l1
    add al, 32
.l1:
    cmp cl, 'A'
    jb .l2
    cmp cl, 'Z'
    ja .l2
    add cl, 32
.l2:
    cmp al, cl
    jne .no
    test al, al
    jz .yes
    inc rdi
    inc rsi
    jmp .c
.yes:
    mov rax, 1
    jmp .out
.no:
    xor rax, rax
.out:
    pop rdi
    pop rsi
    ret

; rsi = src, rdi = dst
copy_str:
    push rdi
.c:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .out
    inc rsi
    inc rdi
    jmp .c
.out:
    pop rdi
    ret

section .rodata
label_address: db "Address:", 0
pfx_download:  db "download:", 0
pfx_http:      db "http://", 0
pfx_https:     db "https://", 0
pfx_nav:       db "nav://", 0

url_home:      db "home", 0
url_apps:      db "apps", 0
url_store:     db "store", 0
url_docs:      db "docs", 0
url_downloads: db "downloads", 0
url_settings:  db "settings", 0
url_discord:   db "discord", 0

page_table:
    dq url_home,      page_home_title,   page_home_lines
    dq url_apps,      page_apps_title,   page_apps_lines
    dq url_store,     page_store_title,  page_store_lines
    dq url_docs,      page_docs_title,   page_docs_lines
    dq url_downloads, page_dl_title,     page_dl_lines
    dq url_settings,  page_set_title,    page_set_lines
    dq url_discord,   page_discord_title, page_discord_lines
    dq 0

page_home_title: db "Navine Home", 0
home_l1: db "Welcome to the Navine browser.", 0
home_l2: db "Type an address: home apps store docs downloads discord", 0
home_l3: db "To install: download:grid-pack", 0
home_l4: db "All content is served locally from NavineFS.", 0
page_home_lines: dq home_l1, home_l2, home_l3, home_l4, 0

page_apps_title: db "App Catalog", 0
apps_l1: db "grid-pack      Navine Grid expansion", 0
apps_l2: db "theme-aurora   Aurora glass theme", 0
apps_l3: db "toolchain-gcc  C/C++ compiler set", 0
apps_l4: db "wallpaper-hd   1080p wallpaper pack", 0
apps_l5: db "Install with download:<name>", 0
page_apps_lines: dq apps_l1, apps_l2, apps_l3, apps_l4, apps_l5, 0

page_store_title: db "Navine Store", 0
store_p1: db "Games: Navine Grid (installed)", 0
store_p2: db "Launchers: Steam Epic GOG wrappers", 0
store_p3: db "Tools: npkg python nodejs rust gcc", 0
page_store_lines: dq store_p1, store_p2, store_p3, 0

page_docs_title: db "Documentation", 0
docs_l1: db "Shortcuts: Space Spotlight  M Mission Control", 0
docs_l2: db "G Game Mode  H Dev Mode  F8 Files  F12 DOOM", 0
docs_l3: db "Terminal: help npkg download downloads game discord", 0
page_docs_lines: dq docs_l1, docs_l2, docs_l3, 0

page_set_title: db "Browser Settings", 0
set_l1: db "Home page: nav://home", 0
set_l2: db "Downloads saved to NavineFS journal", 0
page_set_lines: dq set_l1, set_l2, 0

page_discord_title: db "Discord", 0
disc_l1: db "Navine Discord runs locally on this machine.", 0
disc_l2: db "Open it: terminal discord  or  F10  or  dock D tile", 0
disc_l3: db "Try https://discord.com after TLS is enabled.", 0
page_discord_lines: dq disc_l1, disc_l2, disc_l3, 0

page_net_off_title: db "Network Offline", 0
net_off_l1: db "No NIC detected. VirtualBox needs NAT + 82540EM.", 0
net_off_l2: db "Run build.bat to recreate VM with network.", 0
page_net_off_lines: dq net_off_l1, net_off_l2, 0

page_dl_title: db "Downloads", 0
page_dl_lines: dq 0

page_search_title: db "Address Not Found", 0
search_l1: db "That page is not available locally.", 0
search_l2: db "Available: home apps store docs downloads settings", 0
page_search_lines: dq search_l1, search_l2, 0

dl_empty: db "No downloads yet. Try download:grid-pack", 0
dl_done:  db "100% complete", 0

repo_grid:    db "grid-pack", 0
repo_theme:   db "theme-aurora", 0
repo_gcc:     db "toolchain-gcc", 0
repo_wall:    db "wallpaper-hd", 0
repo_unknown: db "unknown-pkg", 0
repo_table:
    dq repo_grid, repo_theme, repo_gcc, repo_wall, 0

status_ready:      db "Ready.", 0
status_loaded:     db "Page loaded from local repository.", 0
status_remote:     db "Fetched over network.", 0
status_downloaded: db "Download complete. Saved to NavineFS.", 0
status_notfound:   db "Address not found.", 0

dl_term_msg: db "Downloads stored in NavineFS. Open nav://downloads in Browser.", 10, 0
