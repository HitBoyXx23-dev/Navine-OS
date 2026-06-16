/* kernel/fs/sysfs.c */
#include <kernel/fs.h>
static int sysfs_mount(const char *source, const char *target) { (void)source; (void)target; return 0; }
static FileSystemDriver driver = { "sysfs", sysfs_mount };
void sysfs_init(void) { vfs_register(&driver); }
