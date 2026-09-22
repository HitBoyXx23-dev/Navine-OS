#!/bin/bash
set -euo pipefail

VARIANT="${1:-navine}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK="${WORK:-$HOME/navine-debian-$VARIANT}"
OUT="${2:-$ROOT/build/Navine OS Linux Desktop.iso}"
BRAND="$ROOT/linux/branding"
LIVECFG="$ROOT/linux/live-config"

for tool in lb debootstrap xorriso mksquashfs isohybrid; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "ERROR: missing required tool: $tool" >&2
        echo "Install on Debian/Ubuntu: apt-get install live-build debootstrap xorriso squashfs-tools syslinux-utils" >&2
        exit 1
    }
done

echo "=== Navine OS Linux (Debian XFCE) variant: $VARIANT ==="
echo "Work directory: $WORK"
echo "Output ISO:     $OUT"

if ! command -v isohybrid >/dev/null 2>&1; then
    apt-get update -qq
    apt-get install -y -qq syslinux-utils >/dev/null 2>&1 || true
fi
if [ -x /usr/bin/isohybrid ] && [ ! -e /bin/isohybrid ]; then
    ln -sf /usr/bin/isohybrid /bin/isohybrid
fi
export PATH="/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

rm -rf "$WORK"
mkdir -p "$WORK"
cd "$WORK"

lb config \
    --mode debian \
    --architectures amd64 \
    --distribution bookworm \
    --parent-distribution bookworm \
    --parent-mirror-bootstrap "http://deb.debian.org/debian" \
    --parent-mirror-chroot "http://deb.debian.org/debian" \
    --parent-mirror-chroot-security "http://security.debian.org/debian-security" \
    --parent-mirror-binary "http://deb.debian.org/debian" \
    --parent-mirror-binary-security "http://security.debian.org/debian-security" \
    --binary-images iso-hybrid \
    --bootloader grub2 \
    --debian-installer false \
    --archive-areas "main contrib non-free non-free-firmware" \
    --linux-flavours "" \
    --linux-packages none \
    --bootstrap-keyring debian-archive-keyring \
    --keyring-packages "debian-archive-keyring" \
    --security true \
    --apt-recommends true \
    --cache-packages false \
    --cache-stages false \
    --iso-volume "NAVINE_OS" \
    --iso-application "Navine OS" \
    --iso-preparer "Navine OS" \
    --iso-publisher "NavineDevs" \
    --bootappend-live "boot=live components hostname=navine quiet splash" \
    --initramfs live-boot \
    --initsystem systemd \
    --memtest none \
    --ignore-system-defaults

mkdir -p config/package-lists config/hooks/live config/includes.chroot/tmp/navine-branding

cp "$LIVECFG/package-lists/"*.list.chroot config/package-lists/
cp "$LIVECFG/hooks/live/"*.hook.chroot config/hooks/live/
chmod +x config/hooks/live/*.hook.chroot

cp "$BRAND/"* config/includes.chroot/tmp/navine-branding/

if command -v python3 >/dev/null 2>&1; then
    python3 "$ROOT/tools/gen-wallpaper.py" \
        config/includes.chroot/tmp/navine-branding/wallpaper.png
fi

if [ ! -f config/includes.chroot/tmp/navine-branding/wallpaper.png ]; then
    echo "ERROR: wallpaper.png missing; run tools/gen-wallpaper.py" >&2
    exit 1
fi

apt-get update -qq
apt-get install -y -qq debian-archive-keyring ca-certificates >/dev/null 2>&1 || true

echo "Building live image (this may take 20-40 minutes on first run)..."
lb build

ISO=""
for candidate in \
    live-image-amd64.hybrid.iso \
    binary/live-image-amd64.hybrid.iso \
    chroot/binary.hybrid.iso \
    binary.iso \
    live-image-amd64.iso; do
    if [ -f "$candidate" ]; then
        ISO="$candidate"
        break
    fi
done

if [ -z "$ISO" ]; then
    echo "ERROR: lb build finished but no ISO was found" >&2
    ls -la
    exit 1
fi

if command -v isohybrid >/dev/null 2>&1 && [[ "$ISO" == *.iso ]]; then
    isohybrid --uefi "$ISO" 2>/dev/null || isohybrid "$ISO" 2>/dev/null || true
fi

mkdir -p "$(dirname "$OUT")"
cp -f "$ISO" "$OUT"
echo
echo "Built: $OUT"
ls -lh "$OUT"
