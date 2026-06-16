/* kernel/include/kernel/driver.h
 * Language: C17
 * Purpose: Shared driver probe/init contracts.
 */
#ifndef NAVINE_KERNEL_DRIVER_H
#define NAVINE_KERNEL_DRIVER_H

#include <kernel/types.h>

typedef enum {
    DRIVER_OK = 0,
    DRIVER_NOT_FOUND = -1,
    DRIVER_UNSUPPORTED = -2,
    DRIVER_IO_ERROR = -3
} DriverStatus;

typedef struct {
    const char *name;
    DriverStatus (*init)(void);
} KernelDriver;

#endif
