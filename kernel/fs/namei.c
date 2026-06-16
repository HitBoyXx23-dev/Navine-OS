/* kernel/fs/namei.c
 * Language: C17 freestanding
 * Purpose: Minimal absolute path resolver.
 */
#include <kernel/fs.h>

static bool segment_eq(const char *path, uint32_t start, uint32_t len, const char *name) {
    for (uint32_t i = 0; i < len; ++i) {
        if (!name[i] || path[start + i] != name[i]) {
            return false;
        }
    }
    return name[len] == 0;
}

int namei_resolve(const char *path, VfsNode **out) {
    if (!path || path[0] != '/' || !out) {
        return -1;
    }
    VfsNode *root = vfs_root();
    if (path[1] == 0) {
        *out = root;
        return 0;
    }

    uint32_t start = 1;
    while (path[start]) {
        uint32_t len = 0;
        while (path[start + len] && path[start + len] != '/') {
            ++len;
        }
        uint32_t child_index = root->first_child;
        VfsNode *match = 0;
        while (child_index) {
            VfsNode *child = &vfs_root()[child_index];
            if (segment_eq(path, start, len, child->name)) {
                match = child;
                break;
            }
            child_index = child->next_sibling;
        }
        if (!match) {
            return -1;
        }
        root = match;
        start += len;
        if (path[start] == '/') {
            ++start;
        }
    }
    *out = root;
    return 0;
}
