/* kernel/fs/iso9660.c */
#include <kernel/fs.h>
static int iso9660_mount(const char *source, const char *target) { (void)source; (void)target; return -1; }
static FileSystemDriver driver = { "iso9660", iso9660_mount };
void iso9660_init(void) { vfs_register(&driver); }
