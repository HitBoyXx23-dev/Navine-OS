/* kernel/fs/hfsplus.c */
#include <kernel/fs.h>
static int hfsplus_mount(const char *source, const char *target) { (void)source; (void)target; return -1; }
static FileSystemDriver driver = { "hfsplus", hfsplus_mount };
void hfsplus_init(void) { vfs_register(&driver); }
