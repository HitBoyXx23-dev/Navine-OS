"""Generate Navine OS Linux desktop wallpaper."""

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    sys.exit("Pillow required: pip install pillow")


def lerp(a, b, t):
    return int(a + (b - a) * t)


def main():
    out = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("wallpaper.png")
    w, h = 1920, 1080
    top = (0x12, 0x1E, 0x36)
    bottom = (0x05, 0x08, 0x12)
    accent = (0x65, 0xD6, 0xFF)

    img = Image.new("RGB", (w, h))
    px = img.load()
    for y in range(h):
        t = y / max(h - 1, 1)
        r = lerp(top[0], bottom[0], t)
        g = lerp(top[1], bottom[1], t)
        b = lerp(top[2], bottom[2], t)
        for x in range(w):
            px[x, y] = (r, g, b)

    stripe_x = 48
    for y in range(120, h - 120):
        for x in range(stripe_x, stripe_x + 6):
            px[x, y] = accent

    out.parent.mkdir(parents=True, exist_ok=True)
    img.save(out)
    print(f"Wrote {out}")


if __name__ == "__main__":
    main()
