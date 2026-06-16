/* kernel/fs/navinefs.c
 * Language: C17 freestanding
 * Purpose: NavineFS driver registration.
 */
#include <kernel/fs.h>

static int navinefs_mount(const char *source, const char *target) {
    (void)source;
    (void)target;
    return 0;
}

static FileSystemDriver navinefs_driver = {
    .name = "navinefs",
    .mount = navinefs_mount,
};

void navinefs_init(void) {
    vfs_register(&navinefs_driver);
}
