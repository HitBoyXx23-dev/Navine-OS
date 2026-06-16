// gui/include/gui/canvas.hpp
#pragma once
#include <stdint.h>
namespace navine::gui {
struct Color { uint8_t b, g, r, a; };
struct Rect { int x, y, w, h; };
class Canvas {
public:
    Canvas(uint32_t *pixels, int width, int height, int pitch);
    void clear(Color color);
    void fill(Rect rect, Color color);
private:
    uint32_t *pixels_;
    int width_;
    int height_;
    int pitch_;
};
}
