/* kernel/fs/ext4.c */
#include <kernel/fs.h>
static int ext4_mount(const char *source, const char *target) { (void)source; (void)target; return -1; }
static FileSystemDriver driver = { "ext4", ext4_mount };
void ext4_init(void) { vfs_register(&driver); }
