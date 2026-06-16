/* kernel/ipc/semaphore.c */
typedef struct { int value; } Semaphore;
void semaphore_init(Semaphore *s, int value) { if (s) s->value = value; }
