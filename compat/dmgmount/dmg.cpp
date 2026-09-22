// compat/dmgmount/dmg.cpp - macOS DMG mount scaffold
#include <cstdint>

namespace navine::compat {

bool dmg_probe(const unsigned char *data, std::uint32_t size) {
    if (!data || size < 4) return false;
    if (data[0] == 'k' && data[1] == 'o' && data[2] == 'l' && data[3] == 'y') return true;
    if (data[0] == 'h' && data[1] == '+' && data[2] == 'f' && data[3] == 's') return true;
    return false;
}

int dmg_mount_image(const unsigned char *data, std::uint32_t size) {
    if (!dmg_probe(data, size)) return 0;
    return 1;
}

} // namespace navine::compat
