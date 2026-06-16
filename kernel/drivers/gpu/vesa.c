/* kernel/drivers/gpu/vesa.c */
#include <kernel/boot.h>
#include <kernel/driver.h>
static NavineBootInfo gpu_boot_info;
DriverStatus gpu_init_from_boot(const NavineBootInfo *bi) { if (!bi || !bi->fb_base) return DRIVER_NOT_FOUND; gpu_boot_info = *bi; return DRIVER_OK; }
