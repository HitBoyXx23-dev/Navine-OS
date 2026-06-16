; boot/stage1.asm
; Language: NASM x86-16
; Purpose: Navine OS MBR stage 1 bootloader. Loads stage 2 from disk.
; Build: nasm -f bin -I include/ -o build/stage1.bin boot/stage1.asm
; Notes: Must fit in the 446-byte MBR boot code area.

[BITS 16]
[ORG 0x7C00]

%include "constants.inc"

%define BOOT_DRIVE_STORE 0x0500
%define LOAD_RETRIES     3

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti
    cld

    ; BIOS passes the boot drive in DL. Keep it instead of assuming 0x80.
    mov [BOOT_DRIVE_STORE], dl
    mov [boot_drive], dl

    mov si, msg_loading
    call print_string

    call reset_disk
    call load_stage2_lba
    jnc .verify

    ; Old BIOS fallback. VirtualBox should use LBA, but CHS helps real machines.
    call reset_disk
    call load_stage2_chs
    jc disk_error

.verify:
    cmp dword [STAGE2_LOAD_ADDR + STAGE2_MAGIC_OFFSET], STAGE2_MAGIC
    jne stage2_error
    mov dl, [boot_drive]
    jmp 0x0000:STAGE2_LOAD_ADDR

reset_disk:
    xor ax, ax
    mov dl, [boot_drive]
    int 0x13
    ret

; load_stage2_lba()
; Input: boot_drive variable, stage2_dap.
; Output: CF clear on success, CF set on failure.
; Side effects: Loads Stage 2 to physical STAGE2_LOAD_ADDR.
load_stage2_lba:
    mov byte [retry_count], LOAD_RETRIES
.try:
    mov si, stage2_dap
    mov ah, 0x42
    mov dl, [boot_drive]
    int 0x13
    jnc .ok
    call reset_disk
    dec byte [retry_count]
    jnz .try
    stc
    ret
.ok:
    clc
    ret

; load_stage2_chs()
; Input: boot_drive variable.
; Output: CF clear on success, CF set on failure.
; Side effects: Loads one sector at a time from cylinder 0, head 0.
load_stage2_chs:
    xor ax, ax
    mov es, ax
    mov bx, STAGE2_LOAD_ADDR
    mov cl, STAGE2_SECTOR + 1
    mov bp, STAGE2_SECTOR_COUNT
.read:
    mov byte [retry_count], LOAD_RETRIES
.try:
    mov ah, 0x02
    mov al, 1
    xor ch, ch
    xor dh, dh
    mov dl, [boot_drive]
    int 0x13
    jnc .next
    call reset_disk
    dec byte [retry_count]
    jnz .try
    stc
    ret
.next:
    add bx, SECTOR_SIZE
    inc cl
    dec bp
    jnz .read
    clc
    ret

print_string:
    lodsb
    test al, al
    jz .done
    mov ah, 0x0E
    xor bh, bh
    mov bl, 0x07
    int 0x10
    jmp print_string
.done:
    ret

stage2_error:
    mov si, msg_stage2_error
    call print_string
    jmp halt

disk_error:
    mov si, msg_disk_error
    call print_string
    jmp halt

halt:
    cli
.loop:
    hlt
    jmp .loop

boot_drive:  db 0
retry_count: db 0

stage2_dap:
    db 16
    db 0
    dw STAGE2_SECTOR_COUNT
    dw 0
    dw STAGE2_LOAD_ADDR >> 4
    dd STAGE2_SECTOR
    dd 0

msg_loading:      db "Navine OS...", 13, 10, 0
msg_disk_error:   db "Boot error. Check disk.", 13, 10, 0
msg_stage2_error: db "Boot error. Stage2.", 13, 10, 0

times 446 - ($ - $$) db 0

mbr_partition_table:
    db 0x80
    db 0x00, 0x02, 0x00
    db 0x83
    db 0xFE, 0xFF, 0xFF
    dd 1
    dd DISK_TOTAL_SECTORS - 1
    times 48 db 0

dw 0xAA55
