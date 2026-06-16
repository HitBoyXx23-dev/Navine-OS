#include "doomkeys.h"
#include "doomgeneric.h"
#include "navine_compat.h"
#include "navine_hw.h"

#include <string.h>

#define KEYQUEUE_SIZE 32

static unsigned short s_key_queue[KEYQUEUE_SIZE];
static unsigned int s_key_write;
static unsigned int s_key_read;
static uint32_t s_start_ticks;
static int s_offset_x;
static int s_offset_y;
static int s_scale;

static unsigned char convert_scancode(unsigned char sc) {
    switch (sc) {
    case 0x01: return KEY_ESCAPE;
    case 0x1C: return KEY_ENTER;
    case 0x0E: return KEY_BACKSPACE;
    case 0x48: return KEY_UPARROW;
    case 0x50: return KEY_DOWNARROW;
    case 0x4B: return KEY_LEFTARROW;
    case 0x4D: return KEY_RIGHTARROW;
    case 0x2A:
    case 0x36: return KEY_RSHIFT;
    case 0x1D: return KEY_FIRE;
    case 0x39: return KEY_USE;
    default:
        if (sc < 0x3A) {
            static const char map[] = "0123456789";
            if (sc >= 0x02 && sc <= 0x0B) return map[sc - 0x02];
        }
        if (sc >= 0x10 && sc <= 0x19) return "qwertyuiop"[sc - 0x10];
        if (sc >= 0x1E && sc <= 0x26) return "asdfghjkl"[sc - 0x1E];
        if (sc >= 0x2C && sc <= 0x32) return "zxcvbnm"[sc - 0x2C];
        if (sc == 0x39) return ' ';
        return sc;
    }
}

static void queue_key(int pressed, unsigned char key) {
    unsigned short data = ((pressed & 1) << 8) | key;
    s_key_queue[s_key_write % KEYQUEUE_SIZE] = data;
    s_key_write++;
}

static void poll_ps2(void) {
    while (navine_inb(0x64) & 1) {
        unsigned char sc = navine_inb(0x60);
        if (sc & 0x80) {
            queue_key(0, convert_scancode(sc & 0x7F));
        } else {
            queue_key(1, convert_scancode(sc));
        }
    }
}

void DG_Init(void) {
    navine_fb_info_t *fb = navine_fb();
    s_key_write = 0;
    s_key_read = 0;
    s_start_ticks = navine_get_ticks();
    s_scale = 1;
    if (fb->width > DOOMGENERIC_RESX) {
        s_scale = (int)(fb->width / DOOMGENERIC_RESX);
        if (s_scale < 1) s_scale = 1;
    }
    s_offset_x = (int)(fb->width - DOOMGENERIC_RESX * s_scale) / 2;
    s_offset_y = (int)(fb->height - DOOMGENERIC_RESY * s_scale) / 2;
    memset(s_key_queue, 0, sizeof(s_key_queue));
}

void DG_DrawFrame(void) {
    navine_fb_info_t *fb = navine_fb();
    uint32_t *dest;
    uint32_t *src;
    int y;
    int x;
    int sy;
    int sx;

    if (!fb->base || !DG_ScreenBuffer) {
        return;
    }

    poll_ps2();

    dest = (uint32_t *)(uintptr_t)fb->base;
    for (y = 0; y < DOOMGENERIC_RESY; y++) {
        src = &DG_ScreenBuffer[y * DOOMGENERIC_RESX];
        for (sy = 0; sy < s_scale; sy++) {
            int row = s_offset_y + y * s_scale + sy;
            if (row < 0 || (uint32_t)row >= fb->height) continue;
            for (x = 0; x < DOOMGENERIC_RESX; x++) {
                uint32_t pixel = src[x] | 0xFF000000;
                for (sx = 0; sx < s_scale; sx++) {
                    int col = s_offset_x + x * s_scale + sx;
                    if (col < 0 || (uint32_t)col >= fb->width) continue;
                    dest[row * (fb->pitch / 4) + col] = pixel;
                }
            }
        }
    }
}

void DG_SleepMs(uint32_t ms) {
    uint32_t start = navine_get_ticks();
    while ((navine_get_ticks() - start) < ms) {
        poll_ps2();
    }
}

uint32_t DG_GetTicksMs(void) {
    return navine_get_ticks() - s_start_ticks;
}

int DG_GetKey(int *pressed, unsigned char *doomKey) {
    if (s_key_read == s_key_write) {
        return 0;
    }
    unsigned short data = s_key_queue[s_key_read % KEYQUEUE_SIZE];
    s_key_read++;
    *pressed = (data >> 8) & 1;
    *doomKey = data & 0xFF;
    return 1;
}

void DG_SetWindowTitle(const char *title) {
    (void)title;
}

int main(int argc, char **argv) {
    char *fake_argv[] = { "doom", "-iwad", "doom1.wad", NULL };
    (void)argc;
    (void)argv;
    doomgeneric_Create(3, fake_argv);
    for (;;) {
        doomgeneric_Tick();
    }
    return 0;
}
