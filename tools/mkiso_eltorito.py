#!/usr/bin/env python3
"""Create El Torito bootable ISO9660 image for Navine OS.

Boot chain
----------
El Torito HDD-emulation (media type 0x04) is used so that stage1's INT 13h
calls read 512-byte sectors from the embedded disk image, matching the layout
that stage1 and stage2 expect (stage2 at sector 2, kernel at sector 34).
"""

import struct
import sys
from pathlib import Path

ISO_SECTOR = 2048
ISO_FILENAME = "Navine OS.iso"

# El Torito HDD-emulation loads only the MBR (1 sector = 512 bytes).
# The BIOS then maps INT 13h for the virtual drive to the embedded disk image,
# so stage1 can read stage2/kernel from it using normal 512-byte LBA calls.
BOOT_LOAD_SECTORS = 1


def pad(data: bytes, size: int) -> bytes:
    if len(data) >= size:
        return data[:size]
    return data + b"\x00" * (size - len(data))


def ascii_field(text: str, size: int) -> bytes:
    raw = text.encode("ascii", errors="replace")[:size]
    return raw + b" " * (size - len(raw))


def dir_record(name_bytes: bytes, extent: int, size: int, flags: int = 0) -> bytes:
    name_len = len(name_bytes)
    rec_len = 33 + name_len
    if rec_len & 1:
        rec_len += 1          # must be even
    body = bytearray(rec_len)
    body[0] = rec_len
    body[1] = 0               # extended attribute record length
    struct.pack_into("<I", body, 2, extent)
    struct.pack_into(">I", body, 6, extent)
    struct.pack_into("<I", body, 10, size)
    struct.pack_into(">I", body, 14, size)
    # Recording date: year-1900, month, day, hour, min, sec, tz offset
    body[18:25] = bytes([126, 6, 10, 12, 0, 0, 0])   # 2026-06-10 12:00:00 UTC
    body[25] = flags
    body[26] = 0              # file unit size (non-interleaved)
    body[27] = 0              # interleave gap
    struct.pack_into("<H", body, 28, 1)   # volume sequence number LE
    struct.pack_into(">H", body, 30, 1)   # volume sequence number BE
    body[32] = name_len
    body[33:33 + name_len] = name_bytes
    return bytes(body)


def catalog_checksum(entry: bytes) -> int:
    """Sum all 16-bit LE words; result used to produce a zero-sum validation."""
    value = 0
    for i in range(0, len(entry), 2):
        if i + 1 < len(entry):
            value = (value + struct.unpack_from("<H", entry, i)[0]) & 0xFFFF
    return value


def make_boot_catalog(boot_lba: int) -> bytes:
    catalog = bytearray(ISO_SECTOR)

    # --- Validation Entry (32 bytes) ---
    # Bytes 0-1:   header/platform
    # Bytes 2-3:   reserved
    # Bytes 4-27:  ID string (24 bytes)
    # Bytes 28-29: checksum (so that sum of all 16-bit words == 0)
    # Byte  30:    key 0x55
    # Byte  31:    key 0xAA
    validation = bytearray(32)
    validation[0] = 0x01      # header indicator
    validation[1] = 0x00      # platform: 80x86
    validation[4:4 + 9] = b"Navine OS"
    validation[30] = 0x55     # key bytes — required by El Torito spec
    validation[31] = 0xAA
    # Bytes 28-29 = 0 for now; compute checksum over the full 32 bytes
    csum = catalog_checksum(bytes(validation))
    struct.pack_into("<H", validation, 28, (-csum) & 0xFFFF)
    catalog[0:32] = validation

    # --- Initial/Default Boot Entry (32 bytes at offset 32) ---
    # Byte 0:    boot indicator (0x88 = bootable)
    # Byte 1:    boot media type (0x04 = HDD emulation)
    # Bytes 2-3: load segment (0 → BIOS uses 0x07C0 = load to 0x7C00)
    # Byte 4:    system type (partition type from MBR; 0x83 matches mkdisk.ps1)
    # Byte 5:    unused
    # Bytes 6-7: sector count (1 = load MBR only; INT 13h handles the rest)
    # Bytes 8-11: boot image LBA (ISO 2048-byte sector of the disk image)
    entry = bytearray(32)
    entry[0] = 0x88
    entry[1] = 0x04           # HDD emulation
    struct.pack_into("<H", entry, 2, 0x0000)
    entry[4] = 0x83           # Linux partition type (matches stage1/mkdisk)
    entry[5] = 0x00
    struct.pack_into("<H", entry, 6, BOOT_LOAD_SECTORS)
    struct.pack_into("<I", entry, 8, boot_lba)
    catalog[32:64] = entry

    return bytes(catalog)


def build_iso(disk_img: Path, iso_path: Path) -> None:
    disk = disk_img.read_bytes()
    if len(disk) < 512 or disk[510] != 0x55 or disk[511] != 0xAA:
        raise RuntimeError(f"{disk_img} is missing MBR boot signature 0xAA55")

    disk_sectors = (len(disk) + ISO_SECTOR - 1) // ISO_SECTOR
    disk_padded = pad(disk, disk_sectors * ISO_SECTOR)

    readme = (
        b"Navine OS bootable ISO\r\n"
        b"VirtualBox: run run-vbox.bat or attach build\\navine.vdi as hard disk\r\n"
        b"USB: use build\\navine.img with Rufus DD mode\r\n"
    )

    pvd_lba     = 16
    boot_vd_lba = 17
    term_lba    = 18
    root_lba    = 19
    catalog_lba = 20
    pathl_lba   = 21   # L-type (LE) path table
    pathm_lba   = 22   # M-type (BE) path table
    readme_lba  = 32
    disk_lba    = 33

    total_sectors = disk_lba + disk_sectors
    iso = bytearray(total_sectors * ISO_SECTOR)

    # Mirror the disk image into the ISO system area (first 16 sectors / 32 KB)
    # so that any hybrid-aware tool sees the MBR at byte 0.
    iso[0:min(len(disk), 16 * ISO_SECTOR)] = disk[0:min(len(disk), 16 * ISO_SECTOR)]

    # --- Root directory (dot, dotdot, then files) ---
    root = bytearray()
    root += dir_record(b"\x00", root_lba, ISO_SECTOR, flags=0x02)   # . (self)
    root += dir_record(b"\x01", root_lba, ISO_SECTOR, flags=0x02)   # .. (parent)
    root += dir_record(b"NAVINE.IMG;1", disk_lba, len(disk_padded))
    root += dir_record(b"README.TXT;1", readme_lba, len(readme))
    root = pad(bytes(root), ISO_SECTOR)

    # --- L-type path table (little-endian) ---
    pt_entry = struct.pack("BB", 1, 0)           # dir-id length=1, ext-attr=0
    pt_entry += struct.pack("<I", root_lba)      # extent location (LE)
    pt_entry += struct.pack("<H", 1)             # parent directory number (LE)
    pt_entry += b"\x01\x00"                      # dir identifier + even pad
    path_table_l = pad(pt_entry, ISO_SECTOR)

    # --- M-type path table (big-endian) ---
    pt_entry_m = struct.pack("BB", 1, 0)
    pt_entry_m += struct.pack(">I", root_lba)
    pt_entry_m += struct.pack(">H", 1)
    pt_entry_m += b"\x01\x00"
    path_table_m = pad(pt_entry_m, ISO_SECTOR)

    catalog = make_boot_catalog(disk_lba)

    # --- Primary Volume Descriptor ---
    pvd = bytearray(ISO_SECTOR)
    pvd[0] = 1
    pvd[1:6] = b"CD001"
    pvd[6] = 1
    pvd[7] = 0
    pvd[8:40]  = ascii_field("NAVINE_OS", 32)    # System Identifier
    pvd[40:72] = ascii_field("NAVINE OS", 32)    # Volume Identifier
    # bytes 72-79: Unused = 0
    struct.pack_into("<I", pvd, 80, total_sectors)    # Volume Space Size LE
    struct.pack_into(">I", pvd, 84, total_sectors)    # Volume Space Size BE
    # bytes 88-119: Escape Sequences = 0
    struct.pack_into("<H", pvd, 120, 1)               # Volume Set Size LE
    struct.pack_into(">H", pvd, 122, 1)               # Volume Set Size BE
    struct.pack_into("<H", pvd, 124, 1)               # Volume Sequence Number LE
    struct.pack_into(">H", pvd, 126, 1)               # Volume Sequence Number BE
    struct.pack_into("<H", pvd, 128, ISO_SECTOR)      # Logical Block Size LE
    struct.pack_into(">H", pvd, 130, ISO_SECTOR)      # Logical Block Size BE
    pt_size = len(pt_entry)
    struct.pack_into("<I", pvd, 132, pt_size)         # Path Table Size LE
    struct.pack_into(">I", pvd, 136, pt_size)         # Path Table Size BE
    struct.pack_into("<I", pvd, 140, pathl_lba)       # Location of L-Path Table LE
    struct.pack_into("<I", pvd, 144, 0)               # Optional L-Path Table (absent)
    struct.pack_into(">I", pvd, 148, pathm_lba)       # Location of M-Path Table BE
    struct.pack_into(">I", pvd, 152, 0)               # Optional M-Path Table (absent)
    # Root Directory Record at bytes 156-189 (34 bytes)
    root_dr = dir_record(b"\x00", root_lba, ISO_SECTOR, flags=0x02)
    pvd[156:156 + 34] = root_dr[:34]
    pvd[860] = 1   # File Structure Version

    # --- El Torito Boot Record Volume Descriptor ---
    # Bytes 7-38:  Boot System Identifier MUST be "EL TORITO SPECIFICATION" (23 chars, zero-padded to 32)
    # Bytes 71-74: Absolute pointer to Boot Catalog (LE 32-bit)
    boot_vd = bytearray(ISO_SECTOR)
    boot_vd[0] = 0
    boot_vd[1:6] = b"CD001"
    boot_vd[6] = 1
    _id = b"EL TORITO SPECIFICATION"
    boot_vd[7:7 + len(_id)] = _id     # bytes 7-29; bytes 30-38 remain zero
    struct.pack_into("<I", boot_vd, 71, catalog_lba)

    # --- Volume Descriptor Set Terminator ---
    term = bytearray(ISO_SECTOR)
    term[0] = 255
    term[1:6] = b"CD001"
    term[6] = 1

    def put_lba(lba: int, data: bytes) -> None:
        off = lba * ISO_SECTOR
        iso[off:off + len(data)] = data

    put_lba(pvd_lba,     pvd)
    put_lba(boot_vd_lba, boot_vd)
    put_lba(term_lba,    term)
    put_lba(root_lba,    root)
    put_lba(catalog_lba, catalog)
    put_lba(pathl_lba,   path_table_l)
    put_lba(pathm_lba,   path_table_m)
    put_lba(readme_lba,  pad(readme, ISO_SECTOR))
    put_lba(disk_lba,    disk_padded)

    iso_path.write_bytes(iso)
    print(f"Created {iso_path} ({len(iso)} bytes, El Torito HDD-emulation ISO9660)")
    print(f"  PVD at LBA {pvd_lba}, El Torito VD at LBA {boot_vd_lba}")
    print(f"  Boot catalog at LBA {catalog_lba}, disk image at LBA {disk_lba} ({len(disk)} bytes)")


def main() -> int:
    build_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("build")
    disk = build_dir / "navine.img"
    iso = build_dir / ISO_FILENAME
    if not disk.exists():
        print(f"Missing {disk}", file=sys.stderr)
        return 1
    build_iso(disk, iso)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
