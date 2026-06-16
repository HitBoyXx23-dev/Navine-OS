#include "navine_compat.h"
#include "navine_hw.h"
#include <stdio.h>
#include <stdarg.h>
#include <stdint.h>
#include <string.h>
#include <errno.h>
#include <sys/stat.h>

int errno;

#define HEAP_SIZE (8 * 1024 * 1024)
static unsigned char heap_memory[HEAP_SIZE];
static size_t heap_offset;

void *malloc(size_t size) {
    void *ptr;
    size = (size + 15) & ~((size_t)15);
    if (heap_offset + size > HEAP_SIZE) {
        return NULL;
    }
    ptr = &heap_memory[heap_offset];
    heap_offset += size;
    return ptr;
}

void free(void *ptr) {
    (void)ptr;
}

void *calloc(size_t nmemb, size_t size) {
    size_t total = nmemb * size;
    void *ptr = malloc(total);
    if (ptr) {
        memset(ptr, 0, total);
    }
    return ptr;
}

void *realloc(void *ptr, size_t size) {
    void *nptr;
    (void)ptr;
    nptr = malloc(size);
    return nptr;
}

void navine_abort(void) {
    for (;;) {
        __asm__ volatile ("hlt");
    }
}

void abort(void) {
    navine_abort();
}

void exit(int status) {
    (void)status;
    navine_abort();
}

void __main(void) {
}

int navine_printf(const char *fmt, ...) {
    (void)fmt;
    return 0;
}

int printf(const char *fmt, ...) {
    (void)fmt;
    return 0;
}

int fprintf(FILE *stream, const char *fmt, ...) {
    (void)stream;
    (void)fmt;
    return 0;
}

int sprintf(char *str, const char *fmt, ...) {
    (void)fmt;
    if (str) {
        str[0] = 0;
    }
    return 0;
}

FILE __stdin;
FILE __stdout;
FILE __stderr;
FILE *stdin = &__stdin;
FILE *stdout = &__stdout;
FILE *stderr = &__stderr;

int rand(void) {
    static unsigned int seed = 1;
    seed = seed * 1103515245 + 12345;
    return (int)((seed >> 16) & 0x7FFF);
}

void srand(unsigned int s) {
    (void)s;
}

int puts(const char *s) {
    (void)s;
    return 0;
}

void *memset(void *s, int c, size_t n) {
    unsigned char *p = s;
    while (n--) {
        *p++ = (unsigned char)c;
    }
    return s;
}

void *memcpy(void *dest, const void *src, size_t n) {
    unsigned char *d = dest;
    const unsigned char *s = src;
    while (n--) {
        *d++ = *s++;
    }
    return dest;
}

int memcmp(const void *s1, const void *s2, size_t n) {
    const unsigned char *a = s1;
    const unsigned char *b = s2;
    while (n--) {
        if (*a != *b) {
            return *a - *b;
        }
        a++;
        b++;
    }
    return 0;
}

size_t strlen(const char *s) {
    size_t n = 0;
    while (s[n]) {
        n++;
    }
    return n;
}

char *strcpy(char *dest, const char *src) {
    char *d = dest;
    while ((*d++ = *src++)) {
    }
    return dest;
}

char *strncpy(char *dest, const char *src, size_t n) {
    size_t i;
    for (i = 0; i < n && src[i]; i++) {
        dest[i] = src[i];
    }
    for (; i < n; i++) {
        dest[i] = 0;
    }
    return dest;
}

int strcmp(const char *a, const char *b) {
    while (*a && *a == *b) {
        a++;
        b++;
    }
    return (unsigned char)*a - (unsigned char)*b;
}

int strcasecmp(const char *a, const char *b) {
    while (*a && *b) {
        char ca = *a;
        char cb = *b;
        if (ca >= 'A' && ca <= 'Z') ca += 32;
        if (cb >= 'A' && cb <= 'Z') cb += 32;
        if (ca != cb) {
            return ca - cb;
        }
        a++;
        b++;
    }
    return *a - *b;
}

int strncasecmp(const char *a, const char *b, size_t n) {
    while (n && *a && *b) {
        char ca = *a;
        char cb = *b;
        if (ca >= 'A' && ca <= 'Z') ca += 32;
        if (cb >= 'A' && cb <= 'Z') cb += 32;
        if (ca != cb) {
            return ca - cb;
        }
        a++;
        b++;
        n--;
    }
    if (n == 0) {
        return 0;
    }
    return *a - *b;
}

char *strcat(char *dest, const char *src) {
    char *d = dest + strlen(dest);
    while ((*d++ = *src++)) {
    }
    return dest;
}

char *strchr(const char *s, int c) {
    while (*s) {
        if (*s == (char)c) {
            return (char *)s;
        }
        s++;
    }
    return NULL;
}

int atoi(const char *s) {
    int n = 0;
    int sign = 1;
    if (*s == '-') {
        sign = -1;
        s++;
    }
    while (*s >= '0' && *s <= '9') {
        n = n * 10 + (*s - '0');
        s++;
    }
    return n * sign;
}

int abs(int x) {
    return x < 0 ? -x : x;
}

double atof(const char *s) {
    (void)s;
    return 0.0;
}

long strtol(const char *s, char **endptr, int base) {
    long n = 0;
    (void)base;
    while (*s >= '0' && *s <= '9') {
        n = n * 10 + (*s - '0');
        s++;
    }
    if (endptr) {
        *endptr = (char *)s;
    }
    return n;
}

int tolower(int c) {
    if (c >= 'A' && c <= 'Z') {
        return c + 32;
    }
    return c;
}

int toupper(int c) {
    if (c >= 'a' && c <= 'z') {
        return c - 32;
    }
    return c;
}

int isdigit(int c) {
    return c >= '0' && c <= '9';
}

int isspace(int c) {
    return c == ' ' || c == '\t' || c == '\n' || c == '\r';
}

int vsnprintf(char *buf, size_t size, const char *fmt, va_list ap) {
    (void)buf;
    (void)size;
    (void)fmt;
    (void)ap;
    return 0;
}

#include "doomgeneric.h"

int snprintf(char *buf, size_t size, const char *fmt, ...) {
    (void)buf;
    (void)size;
    (void)fmt;
    return 0;
}

int sscanf(const char *s, const char *fmt, ...) {
    (void)s;
    (void)fmt;
    return 0;
}

int system(const char *cmd) {
    (void)cmd;
    return -1;
}

static int navine_is_embedded_wad(const char *path) {
    const char *base;
    const char *p;

    if (!path || navine_wad_size() == 0) {
        return 0;
    }
    base = path;
    for (p = path; *p; p++) {
        if (*p == '/' || *p == '\\') {
            base = p + 1;
        }
    }
    if (strcasecmp(base, "doom1.wad") == 0) {
        return 1;
    }
    if (strcasecmp(base, "doom.wad") == 0) {
        return 1;
    }
    if (strcasecmp(base, "doom2.wad") == 0) {
        return 1;
    }
    return 0;
}

FILE *fopen(const char *path, const char *mode) {
    (void)mode;
    if (navine_is_embedded_wad(path)) {
        return &__stdin;
    }
    return NULL;
}

int fclose(FILE *f) {
    (void)f;
    return 0;
}

size_t fread(void *ptr, size_t size, size_t nmemb, FILE *stream) {
    (void)ptr;
    (void)size;
    (void)nmemb;
    (void)stream;
    return 0;
}

int fseek(FILE *stream, long offset, int whence) {
    (void)stream;
    (void)offset;
    (void)whence;
    return -1;
}

long ftell(FILE *stream) {
    (void)stream;
    return 0;
}

int feof(FILE *stream) {
    (void)stream;
    return 1;
}

int fflush(FILE *stream) {
    (void)stream;
    return 0;
}

int remove(const char *path) {
    (void)path;
    return -1;
}

int rename(const char *oldpath, const char *newpath) {
    (void)oldpath;
    (void)newpath;
    return -1;
}

int _mkdir(const char *path) {
    (void)path;
    return -1;
}

int access(const char *path, int mode) {
    (void)path;
    (void)mode;
    return 0;
}

size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *stream) {
    (void)ptr;
    (void)size;
    (void)nmemb;
    (void)stream;
    return 0;
}

int stat(const char *path, struct stat *st) {
    (void)path;
    (void)st;
    return -1;
}

int isatty(int fd) {
    (void)fd;
    return 0;
}

int fileno(void *stream) {
    (void)stream;
    return -1;
}

void *memmove(void *dest, const void *src, size_t n) {
    unsigned char *d = dest;
    const unsigned char *s = src;
    if (d < s) {
        while (n--) {
            *d++ = *s++;
        }
    } else {
        d += n;
        s += n;
        while (n--) {
            *--d = *--s;
        }
    }
    return dest;
}

char *strdup(const char *s) {
    size_t n = strlen(s) + 1;
    char *d = malloc(n);
    if (d) {
        memcpy(d, s, n);
    }
    return d;
}

char *strrchr(const char *s, int c) {
    const char *last = NULL;
    while (*s) {
        if (*s == (char)c) {
            last = s;
        }
        s++;
    }
    return (char *)last;
}

char *strstr(const char *haystack, const char *needle) {
    size_t nlen;
    if (!*needle) {
        return (char *)haystack;
    }
    nlen = strlen(needle);
    while (*haystack) {
        if (strncmp(haystack, needle, nlen) == 0) {
            return (char *)haystack;
        }
        haystack++;
    }
    return NULL;
}

int strncmp(const char *a, const char *b, size_t n) {
    while (n && *a && *a == *b) {
        a++;
        b++;
        n--;
    }
    if (n == 0) {
        return 0;
    }
    return (unsigned char)*a - (unsigned char)*b;
}

void qsort(void *base, size_t nmemb, size_t size, int (*compar)(const void *, const void *)) {
    (void)base;
    (void)nmemb;
    (void)size;
    (void)compar;
}

double sqrt(double x) {
    double g = x;
    if (x <= 0) return 0;
    for (int i = 0; i < 16; i++) {
        g = 0.5 * (g + x / g);
    }
    return g;
}

double pow(double x, double y) {
    double r = 1;
    int n = (int)y;
    int i;
    for (i = 0; i < n; i++) {
        r *= x;
    }
    return r;
}

double sin(double x) { (void)x; return 0; }
double cos(double x) { (void)x; return 1; }
double tan(double x) { (void)x; return 0; }

double fabs(double x) {
    return x < 0 ? -x : x;
}

int raise(int sig) {
    (void)sig;
    navine_abort();
    return 0;
}

void longjmp(void *env, int val) {
    (void)env;
    (void)val;
    navine_abort();
}

int setjmp(void *env) {
    (void)env;
    return 0;
}

typedef int jmp_buf[16];

int _setjmp(jmp_buf env) {
    return setjmp(env);
}

void _longjmp(jmp_buf env, int val) {
    longjmp(env, val);
}

void __stack_chk_fail(void) {
    navine_abort();
}

void _exit(int code) {
    (void)code;
    navine_abort();
}

int getpid(void) {
    return 1;
}

int unlink(const char *path) {
    (void)path;
    return -1;
}

int mkdir(const char *path, int mode) {
    (void)path;
    (void)mode;
    return -1;
}

int open(const char *path, int flags, ...) {
    (void)path;
    (void)flags;
    return -1;
}

int close(int fd) {
    (void)fd;
    return 0;
}

ssize_t read(int fd, void *buf, size_t count) {
    (void)fd;
    (void)buf;
    (void)count;
    return 0;
}

ssize_t write(int fd, const void *buf, size_t count) {
    (void)fd;
    (void)buf;
    (void)count;
    return 0;
}

void *mmap(void *addr, size_t length, int prot, int flags, int fd, long offset) {
    (void)addr;
    (void)length;
    (void)prot;
    (void)flags;
    (void)fd;
    (void)offset;
    return (void *)-1;
}

int munmap(void *addr, size_t length) {
    (void)addr;
    (void)length;
    return 0;
}

unsigned int sleep(unsigned int seconds) {
    DG_SleepMs(seconds * 1000);
    return 0;
}

int usleep(unsigned long usec) {
    DG_SleepMs((uint32_t)(usec / 1000));
    return 0;
}
