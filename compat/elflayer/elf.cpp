// compat/elflayer/elf.cpp
namespace navine::compat { bool elf_is_valid(const unsigned char *p) { return p && p[0] == 0x7F && p[1] == 'E'; } }
