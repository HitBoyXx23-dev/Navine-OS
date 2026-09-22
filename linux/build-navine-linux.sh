#!/bin/sh
set -e

VERSION="1.0"
ALPINE_BRANCH="v3.21"
ALPINE_RELEASE="3.21.3"
ALPINE_URL="https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/releases/x86_64/alpine-minirootfs-${ALPINE_RELEASE}-x86_64.tar.gz"
KERNEL_URL="https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/releases/x86_64/netboot/vmlinuz-lts"
SYSLINUX_URL="https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-6.03.tar.gz"

WORK="${WORK:-$HOME/navine-linux}"
DL="$WORK/dl"
ROOTFS="$WORK/rootfs"
ISOROOT="$WORK/isoroot"
SYSLINUX="$WORK/syslinux"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT="${1:-$ROOT/build/Navine OS Linux CLI.iso}"

for tool in wget tar cpio gzip xorriso; do
    command -v "$tool" >/dev/null 2>&1 || { echo "ERROR: missing required tool: $tool" >&2; exit 1; }
done

echo "[1/6] Fetching sources"
mkdir -p "$DL"
[ -s "$DL/alpine-minirootfs.tar.gz" ] || wget -q -O "$DL/alpine-minirootfs.tar.gz" "$ALPINE_URL"
[ -s "$DL/vmlinuz-lts" ] || wget -q -O "$DL/vmlinuz-lts" "$KERNEL_URL"
[ -s "$DL/syslinux.tar.gz" ] || wget -q -O "$DL/syslinux.tar.gz" "$SYSLINUX_URL"

echo "[2/6] Unpacking root filesystem"
rm -rf "$ROOTFS" "$ISOROOT"
mkdir -p "$ROOTFS" "$ISOROOT/boot" "$ISOROOT/isolinux"
tar -xzf "$DL/alpine-minirootfs.tar.gz" -C "$ROOTFS" --exclude='./dev/*' 2>/dev/null || true
mkdir -p "$ROOTFS/dev" "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/tmp" "$ROOTFS/run" "$ROOTFS/root"

echo "[3/6] Applying Navine branding"

cat > "$ROOTFS/etc/os-release" <<EOF
NAME="Navine OS Linux CLI"
ID=navine-cli
ID_LIKE=alpine
VERSION_ID=${VERSION}
PRETTY_NAME="Navine OS Linux CLI ${VERSION}"
HOME_URL="https://github.com/NavineDevs"
EOF

echo "navine" > "$ROOTFS/etc/hostname"

cat > "$ROOTFS/etc/issue" <<EOF
Navine OS Linux ${VERSION} \\r \\l

EOF

cat > "$ROOTFS/etc/motd" <<'EOF'
Welcome to Navine OS Linux.

This is a live in-memory system; changes are lost on reboot.
Type 'navine-help' for a short command reference.
EOF

cat > "$ROOTFS/etc/navine-banner" <<'EOF'

    ##    ##    ###    ##     ## #### ##    ## ########
    ###   ##   ## ##   ##     ##  ##  ###   ## ##
    ####  ##  ##   ##  ##     ##  ##  ####  ## ##
    ## ## ## ##     ## ##     ##  ##  ## ## ## ######
    ##  #### #########  ##   ##   ##  ##  #### ##
    ##   ### ##     ##   ## ##    ##  ##   ### ##
    ##    ## ##     ##    ###    #### ##    ## ########

                  N A V I N E   O S   L I N U X

EOF

mkdir -p "$ROOTFS/etc/profile.d"
cat > "$ROOTFS/etc/profile.d/navine.sh" <<'EOF'
export PS1='\[\033[1;36m\]navine\[\033[0m\]:\w# '
export EDITOR=vi
alias ll='ls -la'
EOF

cat > "$ROOTFS/usr/bin/navine-help" <<'EOF'
#!/bin/sh
cat <<'HELP'
Navine OS Linux - command reference

  ls / cd / cat / vi      standard file tools
  ip addr / ip link       network interfaces
  udhcpc -i eth0          request a DHCP lease (also runs at boot)
  ps / top / free         process and memory info
  poweroff / reboot       shut down the machine

Live system: all changes are stored in RAM only.
HELP
EOF
chmod 755 "$ROOTFS/usr/bin/navine-help"

cat > "$ROOTFS/init" <<'EOF'
#!/bin/sh
/bin/busybox --install -s 2>/dev/null

mount -t devtmpfs devtmpfs /dev 2>/dev/null
if [ -c /dev/tty1 ]; then
    exec </dev/tty1 >/dev/tty1 2>&1
else
    exec </dev/console >/dev/console 2>&1
fi

mount -t proc proc /proc 2>/dev/null
mount -t sysfs sysfs /sys 2>/dev/null
mount -t tmpfs tmpfs /tmp 2>/dev/null
mount -t tmpfs tmpfs /run 2>/dev/null
mkdir -p /dev/pts /dev/shm
mount -t devpts devpts /dev/pts 2>/dev/null
mount -t tmpfs tmpfs /dev/shm 2>/dev/null

hostname navine
ip link set lo up 2>/dev/null

for iface in eth0 ens3 enp0s3; do
    if [ -d "/sys/class/net/$iface" ]; then
        ip link set "$iface" up 2>/dev/null
        udhcpc -i "$iface" -n -q -t 5 -T 2 >/dev/null 2>&1 && break
    fi
done

clear
cat /etc/navine-banner
cat /etc/motd
echo
ip addr show scope global 2>/dev/null | sed -n 's/.*inet /  inet /p' | head -3
echo

if [ -c /dev/ttyS0 ]; then
    { cat /etc/navine-banner; cat /etc/motd; echo "Navine OS Linux userspace ready."; ip addr show scope global 2>/dev/null | head -8; } > /dev/ttyS0 2>/dev/null
fi

export HOME=/root
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export TERM=linux

login_shell_count() {
    set -- $(pidof sh 2>/dev/null)
    echo $#
}

busybox setsid -c /bin/sh -l

while true; do
    sleep 2
    if [ "$(login_shell_count)" -le 1 ]; then
        echo
        echo "Restarting Navine OS Linux shell..."
        busybox setsid -c /bin/sh -l
    fi
done
EOF
chmod 755 "$ROOTFS/init"

echo "[4/6] Building initramfs"
( cd "$ROOTFS" && find . -print0 | cpio --null -o -H newc --owner root:root 2>/dev/null ) | gzip -9 > "$ISOROOT/boot/initramfs.gz"
cp "$DL/vmlinuz-lts" "$ISOROOT/boot/vmlinuz"

echo "[5/6] Installing bootloader"
rm -rf "$SYSLINUX"
mkdir -p "$SYSLINUX"
tar -xzf "$DL/syslinux.tar.gz" -C "$SYSLINUX" --strip-components=1
cp "$SYSLINUX/bios/core/isolinux.bin" "$ISOROOT/isolinux/"
cp "$SYSLINUX/bios/com32/elflink/ldlinux/ldlinux.c32" "$ISOROOT/isolinux/"
cp "$SYSLINUX/bios/com32/menu/menu.c32" "$ISOROOT/isolinux/"
cp "$SYSLINUX/bios/com32/libutil/libutil.c32" "$ISOROOT/isolinux/"

cat > "$ISOROOT/isolinux/isolinux.cfg" <<EOF
UI menu.c32
PROMPT 0
TIMEOUT 50
DEFAULT navine

MENU TITLE Navine OS Linux ${VERSION}

LABEL navine
    MENU LABEL Start Navine OS Linux
    LINUX /boot/vmlinuz
    INITRD /boot/initramfs.gz
    APPEND console=ttyS0,115200 console=tty0 quiet

LABEL navineverbose
    MENU LABEL Start Navine OS Linux (verbose boot)
    LINUX /boot/vmlinuz
    INITRD /boot/initramfs.gz
    APPEND console=ttyS0,115200 console=tty0
EOF

echo "[6/6] Creating ISO"
rm -f "$OUT"
xorriso -as mkisofs \
    -o "$OUT" \
    -V "NAVINE_LINUX" \
    -A "Navine OS Linux ${VERSION}" \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -isohybrid-mbr "$SYSLINUX/bios/mbr/isohdpfx.bin" \
    -quiet \
    "$ISOROOT"

echo
echo "Built: $OUT"
ls -lh "$OUT"
