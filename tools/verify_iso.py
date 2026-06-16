#!/usr/bin/env python3
"""Verify Navine OS.iso El Torito and ISO9660 layout."""

import struct
import sys
from pathlib import Path

ISO_SECTOR = 2048
ISO_FILENAME = "Navine OS.iso"
EL_TORITO_ID = b"EL TORITO SPECIFICATION"


def verify(iso_path: Path, disk_path: Path) -> int:
    iso = iso_path.read_bytes()
    disk = disk_path.read_bytes()
    errors = []

    # Primary Volume Descriptor at LBA 16
    pvd = iso[16 * ISO_SECTOR:17 * ISO_SECTOR]
    if pvd[1:6] != b"CD001" or pvd[0] != 1:
        errors.append("Primary Volume Descriptor missing at LBA 16")

    # El Torito Boot Record Volume Descriptor at LBA 17
    boot_vd = iso[17 * ISO_SECTOR:18 * ISO_SECTOR]
    if boot_vd[1:6] != b"CD001" or boot_vd[0] != 0:
        errors.append("El Torito Boot Record VD missing at LBA 17")
    else:
        # Check the exact boot system identifier
        boot_sys_id = boot_vd[7:7 + len(EL_TORITO_ID)]
        if boot_sys_id != EL_TORITO_ID:
            errors.append(
                f"Boot System Identifier is {boot_sys_id!r}, expected {EL_TORITO_ID!r}"
            )
        # Catalog LBA is at byte 71 (LE 32-bit)
        catalog_lba = struct.unpack_from("<I", boot_vd, 71)[0]
        if catalog_lba == 0:
            errors.append("Boot Catalog LBA at byte 71 is zero")
    
    if errors:
        for err in errors:
            print(f"FAIL: {err}")
        return 1

    # Boot catalog
    catalog_lba = struct.unpack_from("<I", boot_vd, 71)[0]
    catalog = iso[catalog_lba * ISO_SECTOR:catalog_lba * ISO_SECTOR + ISO_SECTOR]

    # Validation entry: header=0x01, key bytes 0x55/0xAA at bytes 30-31
    if catalog[0] != 0x01:
        errors.append("Boot catalog validation entry header not 0x01")
    if catalog[30] != 0x55 or catalog[31] != 0xAA:
        errors.append(
            f"Validation entry key bytes are {catalog[30]:02X}/{catalog[31]:02X}, "
            f"expected 55/AA"
        )

    # Verify checksum: sum of all 16-bit LE words in validation entry must be 0
    csum = 0
    for i in range(0, 32, 2):
        csum = (csum + struct.unpack_from("<H", catalog, i)[0]) & 0xFFFF
    if csum != 0:
        errors.append(f"Validation entry checksum bad (sum={csum:#06x}, expected 0)")

    # Initial/Default boot entry at offset 32
    boot_indicator = catalog[32]
    media_type     = catalog[33]
    load_sectors   = struct.unpack_from("<H", catalog, 32 + 6)[0]
    boot_lba       = struct.unpack_from("<I", catalog, 32 + 8)[0]

    if boot_indicator != 0x88:
        errors.append(f"Boot indicator is {boot_indicator:#04x}, expected 0x88")
    if media_type not in (0x00, 0x04):
        errors.append(f"Unexpected boot media type {media_type:#04x}")

    # Verify boot image contains disk MBR
    boot_off = boot_lba * ISO_SECTOR
    if iso[boot_off:boot_off + 512] != disk[0:512]:
        errors.append("Boot image at catalog LBA does not match disk MBR")

    if errors:
        for err in errors:
            print(f"FAIL: {err}")
        return 1

    media_names = {0x00: "no-emulation", 0x04: "HDD-emulation"}
    print(f"OK: {iso_path.name} ({len(iso)} bytes)")
    print(f"  ISO9660 PVD at LBA 16, El Torito Boot VD at LBA 17")
    print(f"  Boot catalog at LBA {catalog_lba}, boot image at LBA {boot_lba}")
    print(f"  Media type: {media_names.get(media_type, media_type)}, "
          f"load sectors: {load_sectors}")
    return 0


def main() -> int:
    build_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("build")
    iso = build_dir / ISO_FILENAME
    disk = build_dir / "navine.img"
    if not iso.exists() or not disk.exists():
        print(f"Missing build/{ISO_FILENAME} or build/navine.img", file=sys.stderr)
        return 1
    return verify(iso, disk)


if __name__ == "__main__":
    raise SystemExit(main())
