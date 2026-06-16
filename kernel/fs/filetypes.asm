; Navine OS - File Type Registry

[BITS 64]

%define FT_UNKNOWN     0
%define FT_TEXT        1
%define FT_BINARY      2
%define FT_WAD         3
%define FT_DOOM        4
%define FT_THEME       5
%define FT_PLUGIN      6
%define FT_MEDIA       7
%define FT_IMAGE       8
%define FT_ARCHIVE     9
%define FT_PE          10
%define FT_SCRIPT      11
%define FT_NAVAPP      12
%define FT_DISK        13
%define FT_JSON        14
%define FT_HTML        15
%define FT_ENTRY_SIZE  16

global init_filetypes
global filetype_get_handler
global filetype_handler_name

section .text
init_filetypes:
    ret

filetype_get_handler:
    push rbx
    push rcx
    push rsi
    mov rsi, rdi
    call find_extension
    test rsi, rsi
    jz .unknown
    mov rdi, rsi
    lea rbx, [ext_table]
.loop:
    cmp byte [rbx], 0
    je .unknown
    push rdi
    push rbx
    mov rsi, rbx
    call match_ext
    pop rbx
    pop rdi
    test rax, rax
    jnz .found
    add rbx, FT_ENTRY_SIZE
    jmp .loop
.found:
    movzx rax, byte [rbx + 12]
    jmp .done
.unknown:
    xor rax, rax
.done:
    pop rsi
    pop rcx
    pop rbx
    ret

filetype_handler_name:
    cmp al, FT_TEXT
    je .text
    cmp al, FT_BINARY
    je .binary
    cmp al, FT_WAD
    je .wad
    cmp al, FT_DOOM
    je .doom
    cmp al, FT_THEME
    je .theme
    cmp al, FT_PLUGIN
    je .plugin
    cmp al, FT_MEDIA
    je .media
    cmp al, FT_IMAGE
    je .image
    cmp al, FT_ARCHIVE
    je .archive
    cmp al, FT_PE
    je .pe
    cmp al, FT_SCRIPT
    je .script
    cmp al, FT_NAVAPP
    je .navapp
    cmp al, FT_DISK
    je .disk
    cmp al, FT_JSON
    je .json
    cmp al, FT_HTML
    je .html
    lea rax, [name_unknown]
    ret
.text:      lea rax, [name_text]; ret
.binary:    lea rax, [name_binary]; ret
.wad:       lea rax, [name_wad]; ret
.doom:      lea rax, [name_doom]; ret
.theme:     lea rax, [name_theme]; ret
.plugin:    lea rax, [name_plugin]; ret
.media:     lea rax, [name_media]; ret
.image:     lea rax, [name_image]; ret
.archive:   lea rax, [name_archive]; ret
.pe:        lea rax, [name_pe]; ret
.script:    lea rax, [name_script]; ret
.navapp:    lea rax, [name_navapp]; ret
.disk:      lea rax, [name_disk]; ret
.json:      lea rax, [name_json]; ret
.html:      lea rax, [name_html]; ret

find_extension:
    mov rsi, rdi
.find_dot:
    movzx ecx, byte [rsi]
    test cl, cl
    jz .none
    cmp cl, '.'
    je .got
    inc rsi
    jmp .find_dot
.got:
    inc rsi
    ret
.none:
    xor rsi, rsi
    ret

match_ext:
    push rsi
    push rdi
.cmp:
    movzx eax, byte [rsi]
    test al, al
    jz .ok
    movzx ecx, byte [rdi]
    test cl, cl
    jz .fail
    mov ah, cl
    cmp al, 'A'
    jb .chk1
    cmp al, 'Z'
    ja .chk1
    add al, 32
.chk1:
    cmp ah, 'A'
    jb .eq
    cmp ah, 'Z'
    ja .eq
    add ah, 32
.eq:
    cmp al, ah
    jne .fail
    inc rsi
    inc rdi
    jmp .cmp
.ok:
    mov rax, 1
    jmp .done
.fail:
    xor rax, rax
.done:
    pop rdi
    pop rsi
    ret

section .rodata
ext_table:
    db "txt",0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "log",0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "md",0,0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "cfg",0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "ini",0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "c",0,0,0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "h",0,0,0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "asm",0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "inc",0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "py",0,0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "xml",0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "yaml",0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "yml",0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "csv",0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "css",0,0,0,0,0,0,0,0,0, FT_TEXT, 0,0,0
    db "json",0,0,0,0,0,0,0,0, FT_JSON, 0,0,0
    db "html",0,0,0,0,0,0,0,0, FT_HTML, 0,0,0
    db "htm",0,0,0,0,0,0,0,0,0, FT_HTML, 0,0,0
    db "js",0,0,0,0,0,0,0,0,0,0, FT_SCRIPT, 0,0,0
    db "ts",0,0,0,0,0,0,0,0,0,0, FT_SCRIPT, 0,0,0
    db "sh",0,0,0,0,0,0,0,0,0,0, FT_SCRIPT, 0,0,0
    db "bat",0,0,0,0,0,0,0,0,0, FT_SCRIPT, 0,0,0
    db "ps1",0,0,0,0,0,0,0,0,0, FT_SCRIPT, 0,0,0
    db "cmd",0,0,0,0,0,0,0,0,0, FT_SCRIPT, 0,0,0
    db "bin",0,0,0,0,0,0,0,0,0, FT_BINARY, 0,0,0
    db "navelf",0,0,0,0,0,0,0, FT_BINARY, 0,0,0
    db "o",0,0,0,0,0,0,0,0,0,0,0, FT_BINARY, 0,0,0
    db "obj",0,0,0,0,0,0,0,0,0, FT_BINARY, 0,0,0
    db "wad",0,0,0,0,0,0,0,0,0, FT_WAD, 0,0,0
    db "doom",0,0,0,0,0,0,0,0, FT_DOOM, 0,0,0
    db "navinetheme",0,0,0, FT_THEME, 0,0,0
    db "theme",0,0,0,0,0,0,0, FT_THEME, 0,0,0
    db "nplugin",0,0,0,0,0,0, FT_PLUGIN, 0,0,0
    db "plugin",0,0,0,0,0,0,0, FT_PLUGIN, 0,0,0
    db "navapp",0,0,0,0,0,0, FT_NAVAPP, 0,0,0
    db "app",0,0,0,0,0,0,0,0,0, FT_NAVAPP, 0,0,0
    db "wav",0,0,0,0,0,0,0,0,0, FT_MEDIA, 0,0,0
    db "mp3",0,0,0,0,0,0,0,0,0, FT_MEDIA, 0,0,0
    db "ogg",0,0,0,0,0,0,0,0,0, FT_MEDIA, 0,0,0
    db "flac",0,0,0,0,0,0,0,0, FT_MEDIA, 0,0,0
    db "mid",0,0,0,0,0,0,0,0,0, FT_MEDIA, 0,0,0
    db "png",0,0,0,0,0,0,0,0,0, FT_IMAGE, 0,0,0
    db "jpg",0,0,0,0,0,0,0,0,0, FT_IMAGE, 0,0,0
    db "jpeg",0,0,0,0,0,0,0,0, FT_IMAGE, 0,0,0
    db "gif",0,0,0,0,0,0,0,0,0, FT_IMAGE, 0,0,0
    db "bmp",0,0,0,0,0,0,0,0,0, FT_IMAGE, 0,0,0
    db "webp",0,0,0,0,0,0,0, FT_IMAGE, 0,0,0
    db "ico",0,0,0,0,0,0,0,0,0, FT_IMAGE, 0,0,0
    db "zip",0,0,0,0,0,0,0,0,0, FT_ARCHIVE, 0,0,0
    db "tar",0,0,0,0,0,0,0,0,0, FT_ARCHIVE, 0,0,0
    db "gz",0,0,0,0,0,0,0,0,0,0, FT_ARCHIVE, 0,0,0
    db "7z",0,0,0,0,0,0,0,0,0,0, FT_ARCHIVE, 0,0,0
    db "rar",0,0,0,0,0,0,0,0,0, FT_ARCHIVE, 0,0,0
    db "exe",0,0,0,0,0,0,0,0,0, FT_PE, 0,0,0
    db "dll",0,0,0,0,0,0,0,0,0, FT_PE, 0,0,0
    db "sys",0,0,0,0,0,0,0,0,0, FT_PE, 0,0,0
    db "iso",0,0,0,0,0,0,0,0,0, FT_DISK, 0,0,0
    db "img",0,0,0,0,0,0,0,0,0, FT_DISK, 0,0,0
    db "vdi",0,0,0,0,0,0,0,0,0, FT_DISK, 0,0,0
    db "vmdk",0,0,0,0,0,0,0,0, FT_DISK, 0,0,0
    db "qcow2",0,0,0,0,0,0, FT_DISK, 0,0,0
    db 0

name_unknown:   db "Unknown", 0
name_text:      db "Text Viewer", 0
name_binary:    db "Binary Loader", 0
name_wad:       db "Navine Grid Data", 0
name_doom:      db "Navine Grid", 0
name_theme:     db "Theme", 0
name_plugin:    db "Plugin", 0
name_media:     db "Navine Audio", 0
name_image:     db "Photos", 0
name_archive:   db "Archive", 0
name_pe:        db "Executable", 0
name_script:    db "Script Runner", 0
name_navapp:    db "Navine App", 0
name_disk:      db "Disk Image", 0
name_json:      db "JSON Viewer", 0
name_html:      db "Browser", 0
