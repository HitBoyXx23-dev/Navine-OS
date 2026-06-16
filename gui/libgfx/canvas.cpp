// gui/libgfx/canvas.cpp
#include <gui/canvas.hpp>
namespace navine::gui {
static uint32_t pack(Color c) { return ((uint32_t)c.a << 24) | ((uint32_t)c.r << 16) | ((uint32_t)c.g << 8) | c.b; }
Canvas::Canvas(uint32_t *pixels, int width, int height, int pitch) : pixels_(pixels), width_(width), height_(height), pitch_(pitch) {}
void Canvas::clear(Color color) { fill({0, 0, width_, height_}, color); }
void Canvas::fill(Rect rect, Color color) {
    if (!pixels_) return;
    if (rect.x < 0) { rect.w += rect.x; rect.x = 0; }
    if (rect.y < 0) { rect.h += rect.y; rect.y = 0; }
    if (rect.x + rect.w > width_) rect.w = width_ - rect.x;
    if (rect.y + rect.h > height_) rect.h = height_ - rect.y;
    if (rect.w <= 0 || rect.h <= 0) return;
    uint32_t v = pack(color);
    for (int y = 0; y < rect.h; ++y) {
        uint32_t *row = pixels_ + (rect.y + y) * pitch_ + rect.x;
        for (int x = 0; x < rect.w; ++x) row[x] = v;
    }
}
}
