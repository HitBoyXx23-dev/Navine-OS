/* kernel/fs/ntfs.c */
#include <kernel/fs.h>
static int ntfs_mount(const char *source, const char *target) { (void)source; (void)target; return -1; }
static FileSystemDriver driver = { "ntfs", ntfs_mount };
void ntfs_init(void) { vfs_register(&driver); }
