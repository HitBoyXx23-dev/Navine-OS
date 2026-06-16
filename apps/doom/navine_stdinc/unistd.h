#ifndef _UNISTD_H
#define _UNISTD_H

#include <sys/types.h>

int isatty(int fd);
unsigned int sleep(unsigned int seconds);
int usleep(unsigned long usec);
int getpid(void);
int access(const char *path, int mode);
ssize_t read(int fd, void *buf, size_t count);
ssize_t write(int fd, const void *buf, size_t count);
int close(int fd);

#endif
