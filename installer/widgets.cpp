// installer/widgets.cpp
#include "widgets.hpp"
namespace navine::installer { bool button_contains(const Button &b, int x, int y) { return x >= b.x && y >= b.y && x < b.x + b.w && y < b.y + b.h; } }
