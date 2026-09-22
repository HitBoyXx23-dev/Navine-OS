# Navine OS

**Navine OS** is a custom operating system project from [NavineDevs](https://github.com/NavineDevs).

The primary product people can use today is **Navine OS Desktop** — a full custom Linux distribution (Debian 12 base, XFCE desktop, Calamares installer) branded as **Horizon**.

There is also a lightweight **CLI** Linux live image, plus experimental **custom-kernel** Desktop/CLI ISOs written in assembly.

## Downloads

**Latest release (v1.0.0):**  
https://github.com/HitBoyXx23-dev/Navine-OS/releases/tag/v1.0.0

| ISO | What you get | Recommended RAM |
|-----|--------------|-----------------|
| `Navine.OS.Linux.Desktop.iso` | **Navine OS Horizon** — XFCE desktop, Firefox, NetworkManager, Calamares installer | **2 GB+** |
| `Navine.OS.Linux.CLI.iso` | Terminal live system (Alpine BusyBox, auto-DHCP) | 512 MB |
| `Navine.OS.Desktop.iso` | Experimental custom kernel + graphical shell | 512 MB |
| `Navine.OS.CLI.iso` | Experimental custom kernel + `navine>` shell | 512 MB |

> Prefer **Linux Desktop** if you want something you can actually use in VirtualBox/QEMU or install to a spare disk.

## What is Navine OS Horizon?

A branded Linux distro built for everyday desktop use:

- **Identity:** `Navine OS 1.0 (Horizon)` in `/etc/os-release`, greeter, GRUB, and installer
- **Desktop:** XFCE with Navine wallpaper, dark panel, Whisker menu
- **Apps:** Firefox ESR, Thunar, Mousepad, GParted, htop, neofetch, git
- **Network / audio:** NetworkManager + PipeWire + common Wi‑Fi firmware packages
- **Install:** Calamares branded as **Install Navine OS**
- **Helpers:** `navine-about`, `navine-help`

Under the hood it is based on **Debian 12 (bookworm)** so `apt` and Debian packages keep working after install.

## Quick start (Linux Desktop)

1. Create a VM (VirtualBox or QEMU) with **2+ GB RAM** and a virtual hard disk.
2. Boot `Navine.OS.Linux.Desktop.iso`.
3. Autologin as `live` into XFCE.
4. To install permanently: open **Install Navine OS** on the desktop and follow Calamares.
5. After install, remove the ISO and boot from the hard disk.

```powershell
powershell -File tools\qemu-test.ps1 -Iso "build\Navine OS Linux Desktop.iso" -OutPng build\qemu\linux-desktop.png -BootSeconds 90 -MemoryMB 2048
```

## Build from source

### Linux Desktop / CLI (recommended)

Requires [WSL](https://learn.microsoft.com/windows/wsl/install) with `live-build`, `debootstrap`, `xorriso`, `squashfs-tools`, `syslinux-utils`.

```bat
build-linux.bat desktop
build-linux.bat cli
build-linux.bat all
```

Desktop builds take 20–40 minutes the first time.

### Custom kernel editions

Requires [NASM](https://www.nasm.us/) and Python 3 + Pillow.

```bat
build.bat
```

## Editions overview

| Edition | Status | Notes |
|---------|--------|-------|
| Navine OS Horizon (Linux Desktop) | **Primary** | Real Linux distro for daily-driver testing |
| Navine OS Linux CLI | Ready | Recovery / terminal live |
| Custom Desktop / CLI kernels | Prototype | Hobby NASM kernel; not a daily driver yet |

## Documentation

- [Production roadmap](docs/PRODUCTION_ROADMAP.md) — VM use first, then real hardware
- [Linux edition guide](docs/LINUX_EDITION.md)
- [Hybrid / custom kernel notes](docs/HYBRID_EDITION.md)
- [Network (custom kernel)](docs/NETWORK.md)

## Repository layout

| Path | Description |
|------|-------------|
| `linux/` | Navine OS Horizon live-build scripts and branding |
| `boot/` `kernel/` | Custom NASM kernel (experimental) |
| `tools/` | ISO, QEMU, VirtualBox, release scripts |
| `apps/doom/` | DOOM port for the custom Desktop edition |
| `docs/` | Design and production docs |

## Release tooling

```powershell
powershell -File tools\release.ps1 -Tag v1.0.1 -Repo HitBoyXx23-dev/Navine-OS
```

## Contributing / upstream

Working tree and ISO releases currently publish from:  
https://github.com/HitBoyXx23-dev/Navine-OS  

Upstream target: https://github.com/NavineDevs/Navine-OS  

## License

See the repository license file (or add one if publishing publicly under a chosen license).
