// libs/navine-libcxx/new.cpp
void *operator new(unsigned long, void *p) noexcept { return p; }
void operator delete(void *, unsigned long) noexcept {}
