/* kernel/drivers/storage/ata.c */
#include <kernel/driver.h>
#include <kernel/io.h>
DriverStatus ata_init(void) { return inb(0x1F7) == 0xFFu ? DRIVER_NOT_FOUND : DRIVER_OK; }
