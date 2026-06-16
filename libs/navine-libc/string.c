/* libs/navine-libc/string.c */
unsigned long strlen(const char *s) { unsigned long n = 0; while (s && s[n]) ++n; return n; }
