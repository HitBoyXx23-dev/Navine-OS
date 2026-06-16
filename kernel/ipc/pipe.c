/* kernel/ipc/pipe.c */
#include <kernel/ipc.h>
int pipe_create(Pipe *pipe) { if (!pipe) return -1; pipe->read_pos = pipe->write_pos = 0; return 0; }
ssize_t pipe_write(Pipe *pipe, const void *buf, size_t len) { (void)pipe; (void)buf; return (ssize_t)len; }
ssize_t pipe_read(Pipe *pipe, void *buf, size_t len) { (void)pipe; (void)buf; (void)len; return 0; }
