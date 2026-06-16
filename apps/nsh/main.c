/* apps/nsh/main.c */
static int streq(const char *a, const char *b) { while (*a && *b && *a == *b) { ++a; ++b; } return *a == *b; }
int nsh_run_command(const char *cmd) { if (streq(cmd, "help")) return 0; if (streq(cmd, "exit")) return 1; return -1; }
int main(void) { return nsh_run_command("help"); }
