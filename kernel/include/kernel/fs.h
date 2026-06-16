/* kernel/include/kernel/fs.h
 * Language: C17
 * Purpose: VFS node and filesystem driver API.
 */
#ifndef NAVINE_KERNEL_FS_H
#define NAVINE_KERNEL_FS_H

#include <kernel/types.h>

#define VFS_NAME_MAX 64u
#define VFS_MAX_NODES 256u

typedef enum {
    VFS_NODE_FILE,
    VFS_NODE_DIR,
    VFS_NODE_DEV
} VfsNodeType;

typedef struct VfsNode {
    char name[VFS_NAME_MAX];
    VfsNodeType type;
    uint64_t size;
    uint32_t parent;
    uint32_t first_child;
    uint32_t next_sibling;
    void *driver_data;
} VfsNode;

typedef struct FileSystemDriver {
    const char *name;
    int (*mount)(const char *source, const char *target);
} FileSystemDriver;

void vfs_init(void);
int vfs_register(FileSystemDriver *driver);
VfsNode *vfs_root(void);
VfsNode *vfs_lookup(const char *path);
int namei_resolve(const char *path, VfsNode **out);

#endif
