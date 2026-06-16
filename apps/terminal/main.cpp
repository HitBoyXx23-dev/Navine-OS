// apps/terminal/main.cpp
namespace navine::apps {
class TerminalApp {
public:
    void write(const char *) {}
    void key(int) {}
};
}
int main() { navine::apps::TerminalApp term; term.write("Navine Terminal\n"); return 0; }
