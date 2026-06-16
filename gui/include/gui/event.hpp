// gui/include/gui/event.hpp
#pragma once
namespace navine::gui {
enum class EventType { None, MouseMove, MouseDown, MouseUp, KeyDown, KeyUp };
struct Event { EventType type; int x; int y; int key; };
}
