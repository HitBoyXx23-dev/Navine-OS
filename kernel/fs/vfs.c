/* kernel/fs/vfs.c
 * Language: C17 freestanding
 * Purpose: In-memory VFS registry and root node.
 */
#include <kernel/fs.h>

#define MAX_FS_DRIVERS 16u

static VfsNode nodes[VFS_MAX_NODES];
static FileSystemDriver *drivers[MAX_FS_DRIVERS];
static uint32_t node_count;
static uint32_t driver_count;

static void copy_name(char *dst, const char *src) {
    uint32_t i = 0;
    while (i + 1u < VFS_NAME_MAX && src && src[i]) {
        dst[i] = src[i];
        ++i;
    }
    dst[i] = 0;
}

void vfs_init(void) {
    node_count = 1;
    driver_count = 0;
    copy_name(nodes[0].name, "/");
    nodes[0].type = VFS_NODE_DIR;
    nodes[0].parent = 0;
    nodes[0].first_child = 0;
    nodes[0].next_sibling = 0;
}

int vfs_register(FileSystemDriver *driver) {
    if (!driver || driver_count >= MAX_FS_DRIVERS) {
        return -1;
    }
    drivers[driver_count++] = driver;
    return 0;
}

VfsNode *vfs_root(void) {
    return &nodes[0];
}

VfsNode *vfs_lookup(const char *path) {
    VfsNode *out = 0;
    if (namei_resolve(path, &out) != 0) {
        return 0;
    }
    return out;
}

VfsNode *vfs_create_static(const char *name, VfsNodeType type, uint32_t parent) {
    if (node_count >= VFS_MAX_NODES) {
        return 0;
    }
    VfsNode *node = &nodes[node_count++];
    copy_name(node->name, name);
    node->type = type;
    node->parent = parent;
    node->next_sibling = nodes[parent].first_child;
    nodes[parent].first_child = node_count - 1u;
    return node;
}
