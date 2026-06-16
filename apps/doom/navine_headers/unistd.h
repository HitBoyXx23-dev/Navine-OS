#ifndef Unistd_H
#define Unistd_H
#include <sys/types.h>
ssize_t read(int fd, void *buf, size_t count);
ssize_t write(int fd, const void *buf, size_t count);
int close(int fd);
int isatty(int fd);
unsigned int sleep(unsigned int seconds);
int usleep(unsigned long usec);
#endif
