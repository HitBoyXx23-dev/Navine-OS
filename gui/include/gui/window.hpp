// gui/include/gui/window.hpp
#pragma once
#include <gui/canvas.hpp>
namespace navine::gui {
class Window {
public:
    Window(Rect frame, const char *title);
    Rect frame() const;
    const char *title() const;
    void move_to(int x, int y);
private:
    Rect frame_;
    const char *title_;
};
}
