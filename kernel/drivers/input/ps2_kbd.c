/* kernel/drivers/input/ps2_kbd.c */
#include <kernel/driver.h>
#include <kernel/io.h>
DriverStatus ps2_keyboard_init(void) { outb(0x64, 0xAE); return DRIVER_OK; }
