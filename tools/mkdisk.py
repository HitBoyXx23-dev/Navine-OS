#!/usr/bin/env python3
"""Create Navine OS disk image with MBR, Stage 2, and kernel."""

import sys
import os

SECTOR = 512
STAGE2_SECTORS = 16
KERNEL_LBA = 20

def pad(data, size):
    if len(data) > size:
        raise ValueError(f"Data exceeds {size} bytes ({len(data)} > {size})")
    return data + bytes(size - len(data))

def main():
    build_dir = sys.argv[1] if len(sys.argv) > 1 else "build"
    stage1 = open(os.path.join(build_dir, "stage1.bin"), "rb").read()
    stage2 = open(os.path.join(build_dir, "stage2.bin"), "rb").read()
    kernel = open(os.path.join(build_dir, "kernel.bin"), "rb").read()

    stage1 = pad(stage1, SECTOR)
    stage2 = pad(stage2, STAGE2_SECTORS * SECTOR)

    img = bytearray()
    img.extend(stage1)
    img.extend(bytes(SECTOR))
    img.extend(stage2)

    kernel_offset = KERNEL_LBA * SECTOR
    if len(img) < kernel_offset:
        img.extend(bytes(kernel_offset - len(img)))
    else:
        img = img[:kernel_offset]
    img.extend(kernel)

    total_sectors = max(len(img) // SECTOR + 1, 2048)
    img.extend(bytes(total_sectors * SECTOR - len(img)))

    out = os.path.join(build_dir, "navine.img")
    with open(out, "wb") as f:
        f.write(img)
    print(f"Created {out} ({len(img)} bytes)")

if __name__ == "__main__":
    main()
