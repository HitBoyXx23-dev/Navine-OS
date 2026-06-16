// gui/compositor.cpp
#include <gui/canvas.hpp>
namespace navine::gui {
class Compositor {
public:
    explicit Compositor(Canvas &canvas) : canvas_(canvas) {}
    void frame() { canvas_.clear({32, 22, 18, 255}); }
private:
    Canvas &canvas_;
};
}
