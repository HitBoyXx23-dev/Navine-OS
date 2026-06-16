// gui/libgfx/font.cpp
#include <gui/font.hpp>
namespace navine::gui {
void draw_text(Canvas &canvas, int x, int y, const char *text, Color color) {
    for (int i = 0; text && text[i]; ++i) {
        canvas.fill({x + i * 7, y, 5, 7}, color);
    }
}
}
