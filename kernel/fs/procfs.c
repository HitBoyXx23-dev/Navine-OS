/* kernel/fs/procfs.c */
#include <kernel/fs.h>
static int procfs_mount(const char *source, const char *target) { (void)source; (void)target; return 0; }
static FileSystemDriver driver = { "procfs", procfs_mount };
void procfs_init(void) { vfs_register(&driver); }
