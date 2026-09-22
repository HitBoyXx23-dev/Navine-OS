; Navine OS - Stage 2 Bootloader

[BITS 16]
[ORG 0x7E00]

%include "constants.inc"

%define FB_INFO_PHYS 0x5000
%define E820_MAP_PHYS 0x6000
%define RSDP_STORE_PHYS 0x5400

jmp short stage2_start
dd STAGE2_MAGIC

stage2_start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7000
    mov [saved_drive], dl
    sti

    mov si, msg_s2
    call print16

    call enable_a20
    jc boot_fail
    call detect_memory_e820
    call find_rsdp16
    call load_kernel16
    jc boot_fail
    call init_vesa16
    call store_fb_info16

    cli
    lgdt [pm_gdt_desc]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:pm_start

[BITS 32]
pm_start:
    cli
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, KERNEL_STACK_TOP
    call verify_long_mode32
    jc pm_halt
    call parse_elf32
    call setup_paging
    call enter_lm

pm_halt:
    cli
.loop:
    hlt
    jmp .loop

[BITS 64]
lm_start:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov rsp, KERNEL_STACK_TOP
    mov rax, [kernel_entry]
    jmp rax

clear_framebuffer64:
    cmp byte [gfx_mode_ok], 1
    jne .ret
    mov edi, [vesa_mode + 0x28]
    test rdi, rdi
    jz .ret
    cmp byte [vesa_mode + 0x19], 8
    je .fill8
    cmp byte [vesa_mode + 0x19], 24
    je .fill24
    mov rcx, VESA_WIDTH
    imul rcx, VESA_HEIGHT
    mov eax, 0xFF2060C0
    rep stosd
    jmp .ret
.fill24:
    mov rcx, VESA_WIDTH
    imul rcx, VESA_HEIGHT
.fill24_loop:
    mov byte [rdi], 0xC0
    mov byte [rdi + 1], 0x60
    mov byte [rdi + 2], 0x20
    add rdi, 3
    loop .fill24_loop
    jmp .ret
.fill8:
    mov rcx, 320 * 200
    mov al, 1
    rep stosb
.ret:
    ret

[BITS 16]
enable_a20:
    call test_a20
    jnc .ok

    mov ax, 0x2401
    int 0x15
    call test_a20
    jnc .ok

    in al, 0x92
    or al, 2
    and al, 0xFE
    out 0x92, al
    call test_a20
    jnc .ok

    call enable_a20_kbc
    call test_a20
    jnc .ok
    stc
    ret
.ok:
    clc
    ret

test_a20:
    push ds
    push es
    push si
    push di
    xor ax, ax
    mov ds, ax
    mov si, 0x0500
    mov ax, 0xFFFF
    mov es, ax
    mov di, 0x0510
    mov al, [ds:si]
    mov ah, [es:di]
    push ax
    mov byte [ds:si], 0xA5
    mov byte [es:di], 0x5A
    cmp byte [ds:si], 0xA5
    pop ax
    mov [es:di], ah
    mov [ds:si], al
    je .enabled
    stc
    jmp .done
.enabled:
    clc
.done:
    pop di
    pop si
    pop es
    pop ds
    ret

enable_a20_kbc:
    call kbc_wait_input_clear
    mov al, 0xAD
    out 0x64, al
    call kbc_wait_input_clear
    mov al, 0xD0
    out 0x64, al
    call kbc_wait_output_full
    in al, 0x60
    push ax
    call kbc_wait_input_clear
    mov al, 0xD1
    out 0x64, al
    call kbc_wait_input_clear
    pop ax
    or al, 2
    out 0x60, al
    call kbc_wait_input_clear
    mov al, 0xAE
    out 0x64, al
    ret

kbc_wait_input_clear:
    mov cx, 0xFFFF
.loop:
    in al, 0x64
    test al, 2
    jz .done
    loop .loop
.done:
    ret

kbc_wait_output_full:
    mov cx, 0xFFFF
.loop:
    in al, 0x64
    test al, 1
    jnz .done
    loop .loop
.done:
    ret

detect_memory_e820:
    push es
    xor ebx, ebx
    xor bp, bp
    mov ax, E820_MAP_PHYS >> 4
    mov es, ax
    xor di, di
.next:
    mov eax, 0xE820
    mov edx, 0x534D4150
    mov ecx, 24
    int 0x15
    jc .done
    cmp eax, 0x534D4150
    jne .done
    add di, 24
    inc bp
    test ebx, ebx
    jz .done
    cmp bp, 32
    jb .next
.done:
    mov [e820_count], bp
    pop es
    ret

find_rsdp16:
    push ds
    push si
    mov word [rsdp_segment], 0xE000
.seg_loop:
    mov ax, [rsdp_segment]
    cmp ax, 0xFFFF
    ja .miss
    mov ds, ax
    xor si, si
.off_loop:
    cmp dword [si], 0x20445352
    jne .next
    cmp dword [si + 4], 0x20525450
    jne .next
    movzx eax, word [rsdp_segment]
    shl eax, 4
    movzx edx, si
    add eax, edx
    mov [RSDP_STORE_PHYS], eax
    jmp .out
.next:
    add si, 16
    jnz .off_loop
    add word [rsdp_segment], 0x1000
    jmp .seg_loop
.miss:
    mov dword [RSDP_STORE_PHYS], 0
.out:
    pop si
    pop ds
    ret

load_kernel16:
    mov dword [kernel_bytes_left], KERNEL_MAX_SECTORS * SECTOR_SIZE
    mov dword [kernel_disk_lba], KERNEL_DISK_SECTOR
    mov dword [kernel_load_phys], KERNEL_LOAD_PHYS
    call query_chs_geometry
.load_loop:
    cmp dword [kernel_bytes_left], 0
    je .done
    mov ax, 1
    mov [kernel_dap + 2], ax
    mov ebx, [kernel_load_phys]
    shr ebx, 4
    mov [kernel_dap + 6], bx
    mov eax, [kernel_disk_lba]
    mov [kernel_dap + 8], eax
    mov si, kernel_dap
    mov ah, 0x42
    mov dl, [saved_drive]
    int 0x13
    jnc .advance
    call read_sector_chs
    jc .load_fail
.advance:
    mov eax, SECTOR_SIZE
    sub [kernel_bytes_left], eax
    add [kernel_load_phys], eax
    inc dword [kernel_disk_lba]
    jmp .load_loop
.load_fail:
    stc
    ret
.done:
    clc
    ret

; Query CHS geometry of the boot drive via INT 13h AH=08h.
; El Torito emulated drives usually lack INT 13h extensions (AH=4xh),
; so CHS is the only reliable access path when booting from CD.
query_chs_geometry:
    push es
    push di
    mov byte [chs_spt], 0
    mov byte [chs_heads], 0
    xor di, di
    mov es, di
    mov ah, 0x08
    mov dl, [saved_drive]
    int 0x13
    jc .out
    mov al, cl
    and al, 0x3F
    mov [chs_spt], al
    mov al, dh
    inc al
    mov [chs_heads], al
.out:
    pop di
    pop es
    ret

; Read the sector at [kernel_disk_lba] into [kernel_load_phys] using CHS.
read_sector_chs:
    push es
    push eax
    push ebx
    push ecx
    push edx

    movzx ebx, byte [chs_spt]
    test bx, bx
    jz .fail
    movzx ecx, byte [chs_heads]
    test cx, cx
    jz .fail

    mov eax, [kernel_disk_lba]
    xor edx, edx
    div ebx
    mov [chs_sector], dl
    inc byte [chs_sector]
    xor edx, edx
    div ecx
    mov [chs_head], dl
    mov [chs_cyl], ax

    mov eax, [kernel_load_phys]
    shr eax, 4
    mov es, ax
    xor bx, bx

    mov ax, [chs_cyl]
    mov ch, al
    mov cl, ah
    shl cl, 6
    or cl, [chs_sector]
    mov dh, [chs_head]
    mov dl, [saved_drive]
    mov ax, 0x0201
    int 0x13
    jc .fail

    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    clc
    ret
.fail:
    pop edx
    pop ecx
    pop ebx
    pop eax
    pop es
    stc
    ret

boot_fail:
    mov si, msg_boot_fail
    call print16
.halt:
    cli
    hlt
    jmp .halt

init_vesa16:
    mov byte [gfx_mode_ok], 0
    mov ah, 0x01
    mov ch, 0x26
    mov cl, 0x00
    int 0x10
    call init_bochs_dispi16
    cmp byte [gfx_mode_ok], 1
    je .pci_fb
    mov dword [vesa_info], 'VBE2'
    mov ax, 0x4F00
    mov di, vesa_info
    int 0x10
    call vesa_pick_best16
    jnc .pci_fb
    mov ax, 0x4F02
    mov bx, 0x4118
    int 0x10
    cmp ax, 0x004F
    je .vesa_set
    mov si, vesa_mode_table
.try_mode:
    mov cx, [si]
    test cx, cx
    jz .try_bochs
    call vesa_try_mode
    cmp byte [gfx_mode_ok], 1
    je .query
    add si, 2
    jmp .try_mode
.try_bochs:
    call init_bochs_dispi16
    cmp byte [gfx_mode_ok], 1
    je .query
    mov ax, 0x4F02
    mov bx, 0x4101
    int 0x10
    cmp ax, 0x004F
    jne .force_fb
.vesa_set:
    mov byte [gfx_mode_ok], 1
    mov word [vesa_selected_mode], 0x118
.query:
    mov cx, [vesa_selected_mode]
    test cx, cx
    jz .pci_fb
    mov ax, 0x4F01
    mov di, vesa_mode
    int 0x10
    jmp .pci_fb
.force_fb:
    mov dword [vesa_mode + 0x28], 0xE0000000
    mov word [vesa_mode + 0x12], VESA_WIDTH
    mov word [vesa_mode + 0x14], VESA_HEIGHT
    mov byte [vesa_mode + 0x19], VESA_BPP
    mov dword [vesa_mode + 0x10], VESA_WIDTH * 4
    mov byte [gfx_mode_ok], 1
.pci_fb:
    call pci_find_framebuffer16
    test eax, eax
    jz .check_fb
    mov [vesa_mode + 0x28], eax
.check_fb:
    cmp dword [vesa_mode + 0x28], 0
    jne .done
    mov ax, 0x0013
    int 0x10
    mov dword [vesa_mode + 0x28], 0x000A0000
    mov word [vesa_mode + 0x12], 320
    mov word [vesa_mode + 0x14], 200
    mov byte [vesa_mode + 0x19], 8
    mov dword [vesa_mode + 0x10], 320
    mov byte [gfx_mode_ok], 1
.done:
    ret

vesa_pick_best16:
    push es
    mov word [vesa_best_mode], 0
    mov word [vesa_best_score], 0
    mov word [vesa_best_score + 2], 0
    mov word [vesa_list_count], 256
    mov ax, [vesa_info + 0x0E]
    mov [vesa_list_off], ax
    mov ax, [vesa_info + 0x10]
    mov [vesa_list_seg], ax
.scan:
    cmp word [vesa_list_count], 0
    je .decide
    dec word [vesa_list_count]
    mov ax, [vesa_list_seg]
    mov es, ax
    mov si, [vesa_list_off]
    mov cx, [es:si]
    cmp cx, 0xFFFF
    je .decide
    add word [vesa_list_off], 2
    mov ax, ds
    mov es, ax
    call vesa_score_mode16
    jmp .scan
.decide:
    mov ax, ds
    mov es, ax
    cmp word [vesa_best_mode], 0
    je .fail
    mov cx, [vesa_best_mode]
    mov [vesa_selected_mode], cx
    mov bx, cx
    or bx, 0x4000
    mov ax, 0x4F02
    int 0x10
    cmp ax, 0x004F
    jne .fail
    mov cx, [vesa_best_mode]
    mov ax, 0x4F01
    mov di, vesa_mode
    int 0x10
    cmp ax, 0x004F
    jne .fail
    mov byte [gfx_mode_ok], 1
    pop es
    clc
    ret
.fail:
    pop es
    stc
    ret

vesa_score_mode16:
    mov [vesa_probe_num], cx
    mov ax, 0x4F01
    mov di, vesa_mode
    int 0x10
    cmp ax, 0x004F
    jne .out
    mov ax, [vesa_mode + 0x00]
    test ax, 0x0001
    jz .out
    test ax, 0x0010
    jz .out
    test ax, 0x0080
    jz .out
    cmp byte [vesa_mode + 0x19], 32
    jne .out
    cmp byte [vesa_mode + 0x1B], 6
    jne .out
    mov ax, [vesa_mode + 0x12]
    test ax, ax
    jz .out
    cmp ax, VESA_MAX_WIDTH
    ja .out
    mov bx, [vesa_mode + 0x14]
    test bx, bx
    jz .out
    cmp bx, VESA_MAX_HEIGHT
    ja .out
    mul bx
    cmp dx, [vesa_best_score + 2]
    ja .better
    jb .out
    cmp ax, [vesa_best_score]
    jbe .out
.better:
    mov [vesa_best_score], ax
    mov [vesa_best_score + 2], dx
    mov cx, [vesa_probe_num]
    mov [vesa_best_mode], cx
.out:
    ret

vesa_try_mode:
    push cx
    mov ax, 0x4F01
    mov di, vesa_mode
    int 0x10
    cmp ax, 0x004F
    jne .fail
    pop cx
    push cx
    mov bx, cx
    or bx, 0x4000
    mov ax, 0x4F02
    int 0x10
    cmp ax, 0x004F
    jne .fail
    pop cx
    mov [vesa_selected_mode], cx
    mov byte [gfx_mode_ok], 1
    ret
.fail:
    pop cx
    ret

init_bochs_dispi16:
    mov byte [gfx_mode_ok], 0
    mov dx, 0x1CE
    xor ax, ax
    out dx, ax
    mov dx, 0x1CF
    in ax, dx
    sub ax, 0xB0C0
    cmp ax, 6
    jae .not_bga
.setup:
    mov dx, 0x1CE
    mov ax, 4
    out dx, ax
    mov dx, 0x1CF
    xor ax, ax
    out dx, ax
    mov dx, 0x1CE
    mov ax, 1
    out dx, ax
    mov dx, 0x1CF
    mov ax, VESA_WIDTH
    out dx, ax
    mov dx, 0x1CE
    mov ax, 2
    out dx, ax
    mov dx, 0x1CF
    mov ax, VESA_HEIGHT
    out dx, ax
    mov dx, 0x1CE
    mov ax, 3
    out dx, ax
    mov dx, 0x1CF
    mov ax, VESA_BPP
    out dx, ax
    mov dx, 0x1CE
    mov ax, 6
    out dx, ax
    mov dx, 0x1CF
    mov ax, VESA_WIDTH
    out dx, ax
    mov dx, 0x1CE
    mov ax, 4
    out dx, ax
    mov dx, 0x1CF
    mov ax, 0x41
    out dx, ax
    mov dword [vesa_mode + 0x28], 0xE0000000
    mov word [vesa_mode + 0x12], VESA_WIDTH
    mov word [vesa_mode + 0x14], VESA_HEIGHT
    mov byte [vesa_mode + 0x19], VESA_BPP
    mov dword [vesa_mode + 0x10], VESA_WIDTH * 4
    mov byte [gfx_mode_ok], 1
    ret
.not_bga:
    ret

store_fb_info16:
    cmp dword [vesa_mode + 0x28], 0
    jne .store
    call pci_find_framebuffer16
    test eax, eax
    jnz .set_fb
    mov dword [vesa_mode + 0x28], 0xE0000000
    jmp .store
.set_fb:
    mov [vesa_mode + 0x28], eax
.store:
    mov ax, FB_INFO_PHYS >> 4
    mov es, ax
    xor di, di
    mov eax, [vesa_mode + 0x28]
    mov [es:di], eax
    mov dword [es:di + 4], 0
    mov ax, [vesa_mode + 0x12]
    test ax, ax
    jnz .store_w
    mov ax, VESA_WIDTH
.store_w:
    mov [es:di + 8], ax
    xor ax, ax
    mov [es:di + 10], ax
    mov ax, [vesa_mode + 0x14]
    test ax, ax
    jnz .store_h
    mov ax, VESA_HEIGHT
.store_h:
    mov [es:di + 12], ax
    xor ax, ax
    mov [es:di + 14], ax
    mov eax, [vesa_mode + 0x10]
    test eax, eax
    jnz .store_p
    mov ax, VESA_WIDTH * 4
.store_p:
    mov [es:di + 16], ax
    xor ax, ax
    mov [es:di + 18], ax
    movzx ax, byte [vesa_mode + 0x19]
    test ax, ax
    jnz .store_bpp
    mov ax, VESA_BPP
.store_bpp:
    mov [es:di + 20], ax
    xor ax, ax
    mov [es:di + 22], ax
    mov al, [gfx_mode_ok]
    mov [es:di + 24], al
    ret

print16:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    int 0x10
    jmp print16
.done:
    ret

gfx_mode_ok: db 0

pci_cfg_addr: dd 0

pci_cfg_read16:
    push dx
    mov eax, [pci_cfg_addr]
    or eax, 0x80000000
    mov dx, 0xCF8
    out dx, eax
    mov dx, 0xCFC
    in eax, dx
    pop dx
    ret

pci_mem_bar16:
    test al, 1
    jnz .zero
    and eax, 0xFFFFFFF0
    ret
.zero:
    xor eax, eax
    ret

pci_find_framebuffer16:
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    xor si, si
.bus:
    cmp si, 4
    jae .miss
    xor di, di
.dev:
    cmp di, 32
    jae .next_bus
    xor bp, bp
.func:
    cmp bp, 8
    jae .next_dev
    movzx eax, si
    shl eax, 16
    movzx ebx, di
    shl ebx, 11
    or eax, ebx
    movzx ebx, bp
    shl ebx, 8
    or eax, ebx
    mov [pci_cfg_addr], eax
    call pci_cfg_read16
    cmp eax, 0xFFFFFFFF
    je .next_func
    cmp eax, 0
    je .next_func
    cmp ax, 0x1234
    jne .chk_vbox
    shr eax, 16
    cmp ax, 0x1111
    je .scan_bars
.chk_vbox:
    mov eax, [pci_cfg_addr]
    and eax, 0xFFFFFF00
    mov [pci_cfg_addr], eax
    call pci_cfg_read16
    cmp ax, 0x80EE
    jne .chk_class
    shr eax, 16
    cmp ax, 0xBEEF
    je .scan_bars
.chk_class:
    mov eax, [pci_cfg_addr]
    and eax, 0xFFFFFF00
    or eax, 8
    mov [pci_cfg_addr], eax
    call pci_cfg_read16
    shr eax, 16
    and eax, 0xFFFF
    cmp ax, 0x0300
    jne .next_func
.scan_bars:
    mov eax, [pci_cfg_addr]
    and eax, 0xFFFFFF00
    mov [pci_cfg_addr], eax
    mov cl, 0x10
.bar_loop:
    mov eax, [pci_cfg_addr]
    and eax, 0xFFFFFF00
    movzx edx, cl
    or eax, edx
    mov [pci_cfg_addr], eax
    call pci_cfg_read16
    call pci_mem_bar16
    test eax, eax
    jnz .hit
    add cl, 4
    cmp cl, 0x20
    jbe .bar_loop
.next_func:
    inc bp
    jmp .func
.next_dev:
    inc di
    jmp .dev
.next_bus:
    inc si
    jmp .bus
.hit:
    jmp .out
.miss:
    xor eax, eax
.out:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    ret

[BITS 32]
verify_long_mode32:
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 1 << 21
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    xor eax, ecx
    test eax, 1 << 21
    jz .fail
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .fail
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz .fail
    clc
    ret
.fail:
    stc
    ret

clear_framebuffer32:
    cmp byte [gfx_mode_ok], 1
    jne .done
    mov esi, [vesa_mode + 0x28]
    test esi, esi
    jnz .have_addr
    mov esi, 0xE0000000
.have_addr:
    cmp byte [vesa_mode + 0x19], 8
    je .fill8
    cmp byte [vesa_mode + 0x19], 24
    je .fill24
    mov edi, esi
    mov ecx, VESA_WIDTH * VESA_HEIGHT
    mov eax, 0xFF2060C0
    rep stosd
    jmp .done
.fill24:
    mov edi, esi
    mov ecx, VESA_WIDTH * VESA_HEIGHT
.fill24_loop:
    mov byte [edi], 0xC0
    mov byte [edi + 1], 0x60
    mov byte [edi + 2], 0x20
    add edi, 3
    loop .fill24_loop
    jmp .done
.fill8:
    mov edi, esi
    mov ecx, 320 * 200
    mov al, 1
    rep stosb
.done:
    ret

parse_elf32:
    mov esi, KERNEL_LOAD_PHYS
    cmp dword [esi], 0x464C457F
    jne .flat
    mov eax, [esi + 0x18]
    mov [kernel_entry], eax
    mov edx, KERNEL_LOAD_PHYS
    movzx ebp, word [esi + 0x38]
    mov ebx, [esi + 0x20]
    add ebx, KERNEL_LOAD_PHYS
    movzx eax, word [esi + 0x36]
    imul eax, 56
    add ebx, eax
.seg_loop:
    test ebp, ebp
    jz .flat
    cmp dword [ebx], 1
    jne .skip
    mov edi, [ebx + 0x10]
    mov esi, [ebx + 0x18]
    add esi, edx
    mov ecx, [ebx + 0x20]
    rep movsb
.skip:
    add ebx, 56
    dec ebp
    jmp .seg_loop
.flat:
    mov dword [kernel_entry], KERNEL_LOAD_PHYS
    ret


setup_paging:
    mov edi, PML4_PHYS
    xor eax, eax
    mov ecx, (PD_PHYS + PD_TABLE_COUNT * 4096 - PML4_PHYS) / 4
    rep stosd

    mov eax, PML4_PHYS
    mov ebx, PDPT_PHYS
    or ebx, 3
    mov [eax], ebx

    mov edi, PDPT_PHYS
    mov ebx, PD_PHYS
    mov ecx, PD_TABLE_COUNT
.fill_pdpt:
    mov eax, ebx
    or eax, 3
    mov [edi], eax
    add edi, 8
    add ebx, 4096
    loop .fill_pdpt

    xor ebx, ebx
    mov edi, PD_PHYS
    mov ecx, PD_TABLE_COUNT
.pd_table:
    push ecx
    push edi
    push ebx
    xor eax, eax
.pd_entry:
    mov edx, ebx
    shl edx, 30
    mov esi, eax
    shl esi, 21
    add edx, esi
    or edx, 0x83
.store_pte:
    mov [edi], edx
    add edi, 8
    inc eax
    cmp eax, 512
    jl .pd_entry
    pop ebx
    pop edi
    add edi, 4096
    inc ebx
    pop ecx
    loop .pd_table

    mov eax, PML4_PHYS
    mov cr3, eax
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax
    ret

enter_lm:
    lgdt [lm_gdt_desc]
    jmp 0x08:lm_start

saved_drive: db 0
chs_spt: db 0
chs_heads: db 0
chs_sector: db 0
chs_head: db 0
chs_cyl: dw 0
e820_count: dw 0
rsdp_segment: dw 0
kernel_entry: dd KERNEL_LOAD_PHYS
kernel_bytes_left: dd 0
kernel_disk_lba: dd 0
kernel_load_phys: dd 0

kernel_dap:
    dw 16
    dw 64
    dw 0x0000
    dw KERNEL_LOAD_PHYS >> 4
    dd KERNEL_DISK_SECTOR
    dd 0

msg_s2: db "Navine OS Stage 2 (x86-64)", 13, 10, 0
msg_boot_fail: db "Stage2 boot failure", 13, 10, 0

vesa_mode_table:
    dw 0x118
    dw 0x117
    dw 0x116
    dw 0x115
    dw 0x103
    dw 0x101
    dw 0x100
    dw 0x0000

vesa_selected_mode: dw 0
vesa_best_mode:  dw 0
vesa_best_score: dd 0
vesa_list_seg:   dw 0
vesa_list_off:   dw 0
vesa_list_count: dw 0
vesa_probe_num:  dw 0

align 8
pm_gdt:
    dq 0
    dq 0x00CF9A000000FFFF
    dq 0x00CF92000000FFFF
pm_gdt_desc:
    dw pm_gdt_desc - pm_gdt - 1
    dd pm_gdt

lm_gdt:
    dq 0
    dq 0x00AF9A000000FFFF
    dq 0x00AF92000000FFFF
lm_gdt_desc:
    dw lm_gdt_desc - lm_gdt - 1
    dd lm_gdt

vesa_info: times 512 db 0
vesa_mode: times 256 db 0

times (STAGE2_SECTOR_COUNT * SECTOR_SIZE) - ($ - $$) db 0
