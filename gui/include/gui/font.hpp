// gui/include/gui/font.hpp
#pragma once
#include <gui/canvas.hpp>
namespace navine::gui {
void draw_text(Canvas &canvas, int x, int y, const char *text, Color color);
}
