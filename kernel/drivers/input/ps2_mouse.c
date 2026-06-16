/* kernel/drivers/input/ps2_mouse.c */
#include <kernel/driver.h>
#include <kernel/io.h>
DriverStatus ps2_mouse_init(void) { outb(0x64, 0xA8); return DRIVER_OK; }
