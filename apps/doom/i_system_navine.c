#include "doomtype.h"
#include "i_system.h"
#include "d_event.h"
#include "d_ticcmd.h"

#include <stdarg.h>

static ticcmd_t emptycmd;

void I_Init(void) {
}

byte *I_ZoneBase(int *size) {
    *size = 0;
    return NULL;
}

boolean I_ConsoleStdout(void) {
    return false;
}

ticcmd_t *I_BaseTiccmd(void) {
    return &emptycmd;
}

void I_Quit(void) {
    for (;;) {
        __asm__ volatile ("hlt");
    }
}

void I_Error(char *error, ...) {
    (void)error;
    for (;;) {
        __asm__ volatile ("hlt");
    }
}

void I_Tactile(int on, int off, int total) {
    (void)on;
    (void)off;
    (void)total;
}

boolean I_GetMemoryValue(unsigned int offset, void *value, int size) {
    (void)offset;
    (void)value;
    (void)size;
    return false;
}

void I_AtExit(atexit_func_t func, boolean run_if_error) {
    (void)func;
    (void)run_if_error;
}

void I_BindVariables(void) {
}

void I_PrintStartupBanner(char *gamedescription) {
    (void)gamedescription;
}

void I_PrintBanner(char *text) {
    (void)text;
}

void I_PrintDivider(void) {
}
