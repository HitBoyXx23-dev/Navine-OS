// gui/window.cpp
#include <gui/window.hpp>
namespace navine::gui {
Window::Window(Rect frame, const char *title) : frame_(frame), title_(title) {}
Rect Window::frame() const { return frame_; }
const char *Window::title() const { return title_; }
void Window::move_to(int x, int y) { frame_.x = x; frame_.y = y; }
}
