// apps/taskmanager/main.cpp
namespace navine::apps { struct ProcessRow { int pid; const char *name; }; int taskmanager_main() { ProcessRow init{1, "navine-init"}; return init.pid == 1 ? 0 : 1; } }
int main() { return navine::apps::taskmanager_main(); }
