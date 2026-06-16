// installer/widgets.hpp
#pragma once
namespace navine::installer {
struct Button { const char *label; int x, y, w, h; };
struct ScreenState { int index; int selected; };
}
