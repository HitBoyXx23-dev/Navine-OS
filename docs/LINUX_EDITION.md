# Navine OS Linux Edition

## Products

| ISO | Base | Role |
|-----|------|------|
| `build/Navine OS Linux Desktop.iso` | Debian 12 XFCE live | Daily-driver desktop |
| `build/Navine OS Linux CLI.iso` | Alpine BusyBox live | Terminal / recovery |

## Build

Requires WSL with root for Desktop (`live-build`, `debootstrap`, `xorriso`, `squashfs-tools`, `syslinux-utils`):

```bat
build-linux.bat desktop
build-linux.bat cli
build-linux.bat all
```

Desktop builds take 20–40 minutes on first run and write under WSL (`~/navine-debian-navine` by default), then copy the ISO to `build/`.

## Run (Phase A — VM testing)

**Linux Desktop:** VirtualBox or QEMU with **2048 MB+ RAM**, VGA, virtio or e1000 NIC. Expect LightDM autologin as `live` into XFCE.

**Linux CLI:** 512 MB is enough. BIOS boot (isolinux). Network: DHCP runs automatically on `eth0`; use `ip addr` to confirm.

```powershell
powershell -File tools\qemu-test.ps1 -Iso "build\Navine OS Linux Desktop.iso" -OutPng build\qemu\linux-desktop.png -BootSeconds 90 -MemoryMB 2048
powershell -File tools\qemu-test.ps1 -Iso "build\Navine OS Linux CLI.iso" -OutPng build\qemu\linux-cli.png -BootSeconds 25 -MemoryMB 512 -SerialLog build\qemu\linux-cli-serial.log
```

## Install to disk (Phase B)

1. Boot Linux Desktop ISO.
2. Open **Install Navine OS Linux** (Calamares) from the desktop.
3. Target an empty virtual disk or spare partition — do not overwrite data you need.
4. After install, remove the ISO and boot from the hard disk.
5. Confirm `/etc/os-release` still identifies as Navine OS Linux.

UEFI: Desktop ISO is built as iso-hybrid with GRUB2; verify in a UEFI VM (OVMF) before claiming hardware support.

## Persistence

Live sessions are RAM-backed by default. Persistence and full Calamares branding are Phase B work items (see `docs/PRODUCTION_ROADMAP.md`).
