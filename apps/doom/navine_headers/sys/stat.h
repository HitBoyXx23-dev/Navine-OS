#ifndef Stat_H
#define Stat_H
struct stat {
    long st_size;
};
int stat(const char *path, struct stat *st);
#endif
