; Navine OS - Monolithic Kernel Link (flat binary, NASM-only native build)
; Build: nasm -f bin -I include/ -I kernel/ -o build/kernel.bin kernel/link.asm

[BITS 64]
[ORG 0x10000]

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
    call boot_fb_ensure
    call init_framebuffer
    call font_init
    call early_framebuffer_paint
    call init_pic
    call init_keyboard
    call init_installer
    call init_compositor
    call compositor_enable_backbuffer
    call init_mouse
    call pic_unmask_keyboard
    call pic_unmask_mouse
    call fb_clear_screen
    call boot_status_draw
    call installer_render
    call compositor_mark_dirty
    call compositor_flip

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
%include "drivers/ahci.asm"
%include "fs/filecache.asm"
%include "gfx/early_fb.asm"
%include "gfx/fbwc.asm"
%include "drivers/serial.asm"
%include "drivers/vga_bga.asm"
%include "drivers/pci.asm"
%include "drivers/rtl8139.asm"
%include "drivers/e1000.asm"
%include "drivers/acpi.asm"
%include "drivers/input/hid.asm"
%include "proc/scheduler.asm"
%include "proc/ipc.asm"
%include "proc/signals.asm"
%include "elf/loader.asm"
%include "compat/pe_loader.asm"
%include "compat/dmg_volume.asm"
%include "compat/linux_syscall.asm"
%include "security/security.asm"
%include "compat/compat.asm"
%include "fs/vfs.asm"
%include "fs/navinefs.asm"
%include "fs/config.asm"
%include "fs/fat32.asm"
%include "fs/ext2.asm"
%include "fs/iso9660.asm"
%include "fs/procfs.asm"
%include "fs/devfs.asm"
%include "gfx/framebuffer.asm"
%include "gfx/font.asm"
%include "gfx/panic_screen.asm"
%include "gfx/boot_status.asm"
%include "gfx/compositor.asm"
%include "wm/window.asm"
%include "desktop/wallpaper.asm"
%include "desktop/installer.asm"
%include "desktop/login.asm"
%include "desktop/desktop.asm"
%include "desktop/theme.asm"
%include "desktop/missionctl.asm"
%include "desktop/plugin.asm"
%include "dev/npkg.asm"
%include "gaming/vulkan_stub.asm"
%include "gaming/game_library.asm"
%include "modes/gamemode.asm"
%include "modes/devmode.asm"
%include "terminal/terminal.asm"
%include "net/stack.asm"
%include "net/internet.asm"
%include "net/dhcp.asm"
%include "net/icmp.asm"
%include "net/tls.asm"
%include "net/websocket.asm"
%include "net/html.asm"
%include "fs/filetypes.asm"
%include "apps/launcher.asm"
%include "apps/webengine.asm"
%include "apps/textviewer.asm"
%include "apps/files.asm"
%include "apps/doom.asm"
%include "apps/cppapp.asm"
%include "apps/simpleapps.asm"
%include "apps/discord.asm"
%include "boot_services.asm"
%include "boot_late.asm"
%include "main.asm"

section .data
fb_info_ptr: dq FB_INFO_PHYS
