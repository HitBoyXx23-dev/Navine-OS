/* kernel/include/kernel/ipc.h */
#ifndef NAVINE_KERNEL_IPC_H
#define NAVINE_KERNEL_IPC_H
#include <kernel/types.h>
typedef struct { uint8_t data[4096]; size_t read_pos; size_t write_pos; } Pipe;
int pipe_create(Pipe *pipe);
ssize_t pipe_write(Pipe *pipe, const void *buf, size_t len);
ssize_t pipe_read(Pipe *pipe, void *buf, size_t len);
#endif
