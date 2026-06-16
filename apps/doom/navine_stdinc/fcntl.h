#ifndef _FCNTL_H
#define _FCNTL_H

#define O_RDONLY 0
#define O_RDWR 1
#define O_WRONLY 2

int open(const char *path, int flags, ...);

#endif
