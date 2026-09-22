; Navine OS - CLI edition kernel (terminal-only, no installer/desktop)
; Build: nasm -f bin -I include/ -I kernel/ -o build/kernel-cli.bin kernel/link-cli.asm

[BITS 64]
[ORG 0x10000]

%define NAVINE_CLI_EDITION
%define NAVINE_LINK_BUILD

%include "constants.inc"
%include "macros.inc"

section .text

global _start
_start:
kernel_entry:
    cli
    cld
    mov rbp, rsp
    and rsp, 0xFFFFFFFFFFFFFFF0

    call init_idt
    call init_serial
    call boot_fb_ensure
    call init_framebuffer
    call font_init
    call fb_clear_screen
    call init_pic
    call init_keyboard
    call pic_unmask_keyboard
    call init_terminal_cli
    lea rsi, [cli_boot_banner]
    call serial_puts

    sti
    call kernel_main

.kernel_halt:
    cli
    hlt
    jmp .kernel_halt

%include "mm/pmm.asm"
%include "mm/vmm.asm"
%include "mm/heap.asm"
%include "arch/idt.asm"
%include "arch/irq.asm"
%include "arch/syscalls.asm"
%include "drivers/pic.asm"
%include "drivers/pit.asm"
%include "drivers/ps2_keyboard.asm"
%include "drivers/ps2_mouse.asm"
%include "drivers/ata.asm"
%include "fs/filecache.asm"
%include "gfx/early_fb.asm"
%include "drivers/serial.asm"
%include "drivers/pci.asm"
%include "drivers/rtl8139.asm"
%include "drivers/e1000.asm"
%include "proc/scheduler.asm"
%include "proc/ipc.asm"
%include "proc/signals.asm"
%include "compat/linux_syscall.asm"
%include "fs/vfs.asm"
%include "fs/navinefs.asm"
%include "fs/config.asm"
%include "fs/fat32.asm"
%include "gfx/framebuffer.asm"
%include "gfx/font.asm"
%include "gfx/panic_screen.asm"
%include "wm/window.asm"
%include "dev/npkg.asm"
%include "gaming/game_library.asm"
%include "terminal/terminal.asm"
%include "net/stack.asm"
%include "net/internet.asm"
%include "net/dhcp.asm"
%include "net/icmp.asm"
%include "net/tls.asm"
%include "net/websocket.asm"
%include "net/html.asm"
%include "apps/webengine.asm"
%include "apps/files.asm"
%include "apps/textviewer.asm"
%include "apps/doom.asm"
%include "cli_stubs.asm"
%include "apps/simpleapps.asm"
%include "apps/discord.asm"
%include "boot_services.asm"
%include "main-cli.asm"

section .rodata
cli_boot_banner:
    db "Navine OS CLI edition", 13, 10, 0

section .data
fb_info_ptr: dq FB_INFO_PHYS
