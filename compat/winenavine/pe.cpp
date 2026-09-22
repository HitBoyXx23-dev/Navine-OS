// compat/winenavine/pe.cpp - Windows PE loader scaffold (WineNavine)
#include <cstdint>

namespace navine::compat {

struct PeHeader {
    std::uint16_t magic;
    std::uint16_t reserved;
    std::uint32_t pe_offset;
};

struct PeOptional {
    std::uint16_t magic;
    std::uint8_t  major;
    std::uint8_t  minor;
};

bool pe_is_valid(const unsigned char *data) {
    if (!data) return false;
    if (data[0] != 'M' || data[1] != 'Z') return false;
    auto *hdr = reinterpret_cast<const PeHeader *>(data);
    if (hdr->pe_offset < 0x40) return false;
    const auto *pe = data + hdr->pe_offset;
    return pe[0] == 'P' && pe[1] == 'E' && pe[2] == 0 && pe[3] == 0;
}

int pe_load_profile(const unsigned char *data, int profile) {
    if (!pe_is_valid(data)) return 0;
    (void)profile;
    return 1;
}

} // namespace navine::compat
