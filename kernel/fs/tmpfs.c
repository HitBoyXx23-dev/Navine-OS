/* kernel/fs/tmpfs.c */
#include <kernel/fs.h>
static int tmpfs_mount(const char *source, const char *target) { (void)source; (void)target; return 0; }
static FileSystemDriver driver = { "tmpfs", tmpfs_mount };
void tmpfs_init(void) { vfs_register(&driver); }
