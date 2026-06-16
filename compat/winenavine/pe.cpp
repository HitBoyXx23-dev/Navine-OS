// compat/winenavine/pe.cpp
namespace navine::compat { bool pe_is_valid(const unsigned char *p) { return p && p[0] == 'M' && p[1] == 'Z'; } }
