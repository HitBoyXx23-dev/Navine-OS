/* kernel/fs/fat.c */
#include <kernel/fs.h>
static int fat_mount(const char *source, const char *target) { (void)source; (void)target; return -1; }
static FileSystemDriver driver = { "fat", fat_mount };
void fat_init(void) { vfs_register(&driver); }
