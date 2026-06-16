/* kernel/printk.c
 * Language: C17 freestanding
 * Purpose: Early framebuffer text console and panic output.
 */
#include <kernel/boot.h>
#include <kernel/printk.h>

static volatile uint32_t *console_fb;
static uint32_t console_width;
static uint32_t console_height;
static uint32_t console_pitch_pixels;
static uint32_t cursor_x;
static uint32_t cursor_y;

static void put_block(uint32_t x, uint32_t y, uint32_t color) {
    if (!console_fb || x >= console_width || y >= console_height) {
        return;
    }
    console_fb[y * console_pitch_pixels + x] = color;
}

static void draw_char(char ch) {
    if (ch == '\n') {
        cursor_x = 0;
        cursor_y += 10;
        return;
    }
    if (cursor_y + 8 >= console_height) {
        cursor_x = 0;
        cursor_y = 0;
    }
    for (uint32_t row = 0; row < 7; ++row) {
        for (uint32_t col = 0; col < 5; ++col) {
            uint32_t on = ((uint8_t)ch + row + col) & 1u;
            if (ch != ' ' && on) {
                put_block(cursor_x + col, cursor_y + row, 0xFFFFFFFFu);
            }
        }
    }
    cursor_x += 7;
    if (cursor_x + 7 >= console_width) {
        cursor_x = 0;
        cursor_y += 10;
    }
}

void early_console_init(const NavineBootInfo *boot_info) {
    if (!boot_info || boot_info->fb_bpp != 32 || boot_info->fb_base == 0) {
        return;
    }
    console_fb = (volatile uint32_t *)(uintptr_t)boot_info->fb_base;
    console_width = boot_info->fb_width;
    console_height = boot_info->fb_height;
    console_pitch_pixels = boot_info->fb_pitch / 4u;
    cursor_x = 16;
    cursor_y = 16;
}

void early_puts(const char *text) {
    if (!text) {
        return;
    }
    while (*text) {
        draw_char(*text++);
    }
}

void printk(const char *fmt, ...) {
    early_puts(fmt);
}

NAVINE_NORETURN void kernel_panic(const char *reason) {
    if (console_fb) {
        for (uint32_t y = 0; y < console_height; ++y) {
            for (uint32_t x = 0; x < console_width; ++x) {
                console_fb[y * console_pitch_pixels + x] = 0xFF071A3Du;
            }
        }
    }
    cursor_x = 24;
    cursor_y = 24;
    early_puts("Navine OS - Kernel Panic\n");
    early_puts(reason ? reason : "unknown panic");
    for (;;) {
        __asm__ volatile("cli; hlt");
    }
}
