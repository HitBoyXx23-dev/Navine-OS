#ifndef NAVINE_COMPAT_H
#define NAVINE_COMPAT_H

#ifdef NAVINE_OS

#undef _WIN32

#define NAVINE_FB_INFO_PHYS     0x00005000
#define NAVINE_WAD_PHYS         0x03000000
#define NAVINE_WAD_SIZE_PHYS    0x00005020
#define NAVINE_DOOM_LOAD_PHYS   0x02000000

int navine_printf(const char *fmt, ...);
void navine_abort(void);

#endif

#endif
