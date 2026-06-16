// apps/browser/main.cpp
namespace navine::browser {
struct Node { const char *tag; };
class Browser { public: bool load_html(const char *) { return true; } };
}
int main() { navine::browser::Browser b; return b.load_html("<html></html>") ? 0 : 1; }
