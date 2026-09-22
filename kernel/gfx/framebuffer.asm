; Navine OS - Framebuffer and VESA

[BITS 64]

%include "constants.inc"

global init_framebuffer
global fb_clear_screen
global fb_base
global fb_bpp
global fb_width
global fb_height
global fb_pitch
global fb_put_pixel
global fb_fill_rect
global fb_draw_rect

extern vga_probe_framebuffer

section .bss
fb_base:        resq 1
fb_width:       resd 1
fb_height:      resd 1
fb_pitch:       resd 1
fb_bpp:         resd 1

section .text
init_framebuffer:
    mov rax, FB_INFO_PHYS
    mov rbx, [rax]
    test rbx, rbx
    jnz .from_boot
    mov rbx, 0xE0000000
    mov [rax], rbx
.from_boot:
    cmp rbx, 0x00F00000
    jb .use_default
    mov [fb_base], rbx
    jmp .dims
.use_default:
    mov rbx, 0xE0000000
    mov [rax], rbx
    mov [fb_base], rbx
.dims:
    mov eax, [rax + 8]
    test eax, eax
    jnz .store_w
    mov eax, VESA_WIDTH
.store_w:
    mov [fb_width], eax
    mov rax, FB_INFO_PHYS
    mov eax, [rax + 12]
    test eax, eax
    jnz .store_h
    mov eax, VESA_HEIGHT
.store_h:
    mov [fb_height], eax
    mov rax, FB_INFO_PHYS
    mov eax, [rax + 16]
    test eax, eax
    jnz .store_p
    mov eax, VESA_WIDTH * 4
.store_p:
    mov [fb_pitch], eax
    mov rax, FB_INFO_PHYS
    mov eax, [rax + FB_INFO_BPP_OFF]
    test eax, eax
    jnz .store_bpp
    mov eax, VESA_BPP
.store_bpp:
    mov [fb_bpp], eax
    cmp dword [fb_bpp], 0
    jne .out
    mov dword [fb_bpp], 32
.out:
    ret

fb_clear_screen:
    mov rdi, [fb_base]
    test rdi, rdi
    jz .done
    cmp dword [fb_bpp], 8
    je .clear8
    cmp dword [fb_bpp], 24
    je .clear24
    mov edi, 0
    mov esi, 0
    mov edx, [fb_width]
    mov ecx, [fb_height]
    mov r8d, 0xFF0A0A12
    call fb_fill_rect
    jmp .done
.clear8:
    push rbx
    mov r9d, [fb_height]
    mov r10d, [fb_pitch]
    xor ebx, ebx
.c8row:
    cmp ebx, r9d
    jge .c8done
    mov eax, ebx
    imul rax, r10
    mov rdi, [fb_base]
    add rdi, rax
    mov ecx, [fb_width]
    mov al, 0x01
    rep stosb
    inc ebx
    jmp .c8row
.c8done:
    pop rbx
    jmp .done
.clear24:
    mov edi, 0
    mov esi, 0
    mov edx, [fb_width]
    mov ecx, [fb_height]
    mov r8d, 0xFF0A0A12
    call fb_fill_rect
.done:
    ret

fb_put_pixel:
    cmp edi, [fb_width]
    jae .done
    cmp esi, [fb_height]
    jae .done
    cmp dword [fb_bpp], 8
    je .put8
    cmp dword [fb_bpp], 24
    je .put24
    mov r8d, edx
    mov eax, [fb_pitch]
    mul esi
    mov ecx, eax
    mov eax, edi
    shl eax, 2
    add ecx, eax
    mov rax, [fb_base]
    add rax, rcx
    mov [rax], r8d
    jmp .done
.put24:
    push rbx
    mov eax, esi
    imul eax, [fb_pitch]
    mov ecx, edi
    lea ecx, [ecx + ecx * 2]
    add eax, ecx
    mov rcx, [fb_base]
    add rcx, rax
    mov eax, edx
    mov [rcx], al
    shr eax, 8
    mov [rcx + 1], al
    shr eax, 8
    mov [rcx + 2], al
    pop rbx
    jmp .done
.put8:
    mov eax, esi
    imul eax, [fb_pitch]
    add eax, edi
    mov rcx, [fb_base]
    add rcx, rax
    mov eax, edx
    cmp eax, 0xFFFFFFFF
    je .c_white
    cmp eax, COLOR_NAVINE_BLUE
    je .c_blue
    cmp eax, COLOR_NAVINE_GRAY
    je .c_gray
    cmp eax, 0xFF888888
    je .c_gray
    cmp eax, 0xFFAAAAAA
    je .c_ltgray
    cmp eax, 0xFF1C1C1E
    je .c_dark
    cmp eax, 0xFF000000
    je .c_black
    mov al, 1
    jmp .store8
.c_white:
    mov al, 15
    jmp .store8
.c_blue:
    mov al, 9
    jmp .store8
.c_gray:
    mov al, 8
    jmp .store8
.c_ltgray:
    mov al, 7
    jmp .store8
.c_dark:
    mov al, 0
    jmp .store8
.c_black:
    mov al, 0
.store8:
    mov [rcx], al
.done:
    ret

fb_fill_rect:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r9d, esi
    mov r10d, edx
    mov r11d, ecx
    mov r12d, r8d
    test r10d, r10d
    jle .out
    test r11d, r11d
    jle .out
    test edi, edi
    jge .clip_y
    add r10d, edi
    xor edi, edi
    test r10d, r10d
    jle .out
.clip_y:
    test r9d, r9d
    jge .clip_right
    add r11d, r9d
    xor r9d, r9d
    test r11d, r11d
    jle .out
.clip_right:
    mov eax, [fb_width]
    cmp edi, eax
    jge .out
    sub eax, edi
    cmp r10d, eax
    jle .clip_bottom
    mov r10d, eax
.clip_bottom:
    mov eax, [fb_height]
    cmp r9d, eax
    jge .out
    sub eax, r9d
    cmp r11d, eax
    jle .clip_done
    mov r11d, eax
.clip_done:
    cmp dword [fb_bpp], 32
    je .rect32
    cmp dword [fb_bpp], 24
    je .rect24
.row:
    test r11d, r11d
    jz .out
    mov esi, r9d
    mov ecx, r10d
    mov ebx, edi
.col:
    test ecx, ecx
    jz .next_row
    mov edi, ebx
    mov edx, r12d
    call fb_put_pixel
    inc ebx
    dec ecx
    jmp .col
.next_row:
    inc r9d
    dec r11d
    jmp .row
.out:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp
    ret

.rect32:
    test r11d, r11d
    jz .out
    mov eax, r9d
    imul eax, [fb_pitch]
    mov r13d, edi
    shl r13d, 2
    add eax, r13d
    mov r13, [fb_base]
    add r13, rax
.rect32_row:
    test r11d, r11d
    jz .out
    mov r14, r13
    mov r15d, r10d
.rect32_col:
    test r15d, r15d
    jz .rect32_next
    mov [r14], r12d
    add r14, 4
    dec r15d
    jmp .rect32_col
.rect32_next:
    mov eax, [fb_pitch]
    add r13, rax
    dec r11d
    jmp .rect32_row

.rect24:
    test r11d, r11d
    jz .out
    mov eax, r9d
    imul eax, [fb_pitch]
    mov r13d, edi
    lea r13d, [r13d + r13d * 2]
    add eax, r13d
    mov r13, [fb_base]
    add r13, rax
.rect24_row:
    test r11d, r11d
    jz .out
    mov r14, r13
    mov r15d, r10d
.rect24_col:
    test r15d, r15d
    jz .rect24_next
    mov eax, r12d
    mov [r14], al
    shr eax, 8
    mov [r14 + 1], al
    shr eax, 8
    mov [r14 + 2], al
    add r14, 3
    dec r15d
    jmp .rect24_col
.rect24_next:
    mov eax, [fb_pitch]
    add r13, rax
    dec r11d
    jmp .rect24_row

fb_draw_rect:
    push rdi
    push rsi
    push rdx
    push rcx
    mov r8d, r8d
    call fb_fill_rect
    pop rcx
    pop rdx
    pop rsi
    pop rdi
    ret
