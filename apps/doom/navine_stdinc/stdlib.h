#ifndef _STDLIB_H
#define _STDLIB_H

#include <stddef.h>

void *malloc(size_t size);
void free(void *ptr);
void *calloc(size_t nmemb, size_t size);
void *realloc(void *ptr, size_t size);
void abort(void);
void exit(int status);
int abs(int x);
int atoi(const char *s);
double atof(const char *s);
long strtol(const char *s, char **endptr, int base);
int rand(void);
void srand(unsigned int seed);

#endif
