#include "navine_compat.h"
#include "navine_hw.h"
#include "m_misc.h"
#include "w_file.h"
#include "z_zone.h"

#include <stddef.h>

typedef struct {
    wad_file_t wad;
    uint8_t *data;
    size_t length;
} navine_wad_file_t;

static wad_file_t *W_Navine_OpenFile(char *path);
static void W_Navine_CloseFile(wad_file_t *wad);
static size_t W_Navine_Read(wad_file_t *wad, unsigned int offset, void *buffer, size_t buffer_len);

wad_file_class_t stdc_wad_file;

static wad_file_t *W_Navine_OpenFile(char *path) {
    navine_wad_file_t *result;
    (void)path;
    result = Z_Malloc(sizeof(navine_wad_file_t), PU_STATIC, 0);
    result->data = navine_wad_base();
    result->length = navine_wad_size();
    if (result->length == 0 || result->data[0] != 'P' || result->data[1] != 'W') {
        Z_Free(result);
        return NULL;
    }
    result->wad.file_class = &stdc_wad_file;
    result->wad.mapped = result->data;
    result->wad.length = (unsigned int)result->length;
    return &result->wad;
}

static void W_Navine_CloseFile(wad_file_t *wad) {
    Z_Free(wad);
}

static size_t W_Navine_Read(wad_file_t *wad, unsigned int offset, void *buffer, size_t buffer_len) {
    navine_wad_file_t *navine_wad = (navine_wad_file_t *)wad;
    size_t remain;
    if (offset >= navine_wad->length) {
        return 0;
    }
    remain = navine_wad->length - offset;
    if (buffer_len > remain) {
        buffer_len = remain;
    }
    memcpy(buffer, navine_wad->data + offset, buffer_len);
    return buffer_len;
}

wad_file_class_t stdc_wad_file = {
    W_Navine_OpenFile,
    W_Navine_CloseFile,
    W_Navine_Read,
};
