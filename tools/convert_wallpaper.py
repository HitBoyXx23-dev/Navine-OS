#!/usr/bin/env python3
"""Convert desktop wallpaper PNG to raw BGRA framebuffer data."""

import struct
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow required (pip install pillow)", file=sys.stderr)
    raise SystemExit(1)

WIDTH = 1920
HEIGHT = 1080


def convert(src: Path, dst: Path) -> None:
    img = Image.open(src).convert("RGBA")
    img = img.resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)
    pixels = img.tobytes()
    out = bytearray()
    for i in range(0, len(pixels), 4):
        r, g, b, a = pixels[i], pixels[i + 1], pixels[i + 2], pixels[i + 3]
        out += struct.pack("<I", (a << 24) | (r << 16) | (g << 8) | b)
    if len(out) != WIDTH * HEIGHT * 4:
        raise RuntimeError(f"Unexpected output size {len(out)}")
    dst.write_bytes(out)
    print(f"Created {dst} ({WIDTH}x{HEIGHT} BGRA, {len(out)} bytes)")


def main() -> int:
    root = Path(__file__).resolve().parent.parent
    src = root / "assets" / "wallpaper.png"
    if not src.exists():
        src = root / "assets" / "background.png"
    build_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else root / "build"
    dst = build_dir / "wallpaper.raw"
    if not src.exists():
        print(f"Missing {src}", file=sys.stderr)
        return 1
    build_dir.mkdir(parents=True, exist_ok=True)
    convert(src, dst)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
