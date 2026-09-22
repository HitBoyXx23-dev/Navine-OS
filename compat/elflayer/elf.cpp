// compat/elflayer/elf.cpp - Linux ELF loader scaffold
#include <cstdint>

namespace navine::compat {

bool elf_is_valid(const unsigned char *data) {
    if (!data) return false;
    return data[0] == 0x7F && data[1] == 'E' && data[2] == 'L' && data[3] == 'F';
}

int elf_load_profile(const unsigned char *data, int sandbox_level) {
    if (!elf_is_valid(data)) return 0;
    (void)sandbox_level;
    return 1;
}

} // namespace navine::compat
