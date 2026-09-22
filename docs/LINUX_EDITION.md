# Navine OS Linux (Horizon)

Navine OS Horizon is the **custom Linux distribution** edition of Navine OS.

## Identity

| Field | Value |
|-------|-------|
| Product | Navine OS |
| Version | 1.0 (Horizon) |
| ID | `navine` |
| Base | Debian 12 bookworm |
| Desktop | XFCE |
| Installer | Calamares (`Install Navine OS`) |

Files applied at image build time:

- `/etc/os-release`, `/etc/lsb-release`, `/etc/navine-release`
- LightDM greeter + XFCE skel layout
- Calamares branding `navine`
- `navine-about` / `navine-help`
- Wallpaper under `/usr/share/backgrounds/navine/`

## Build

```bat
build-linux.bat desktop
```

Script: [`linux/build-navine-debian.sh`](../linux/build-navine-debian.sh)  
Branding: [`linux/branding/`](../linux/branding/)  
Hooks: [`linux/live-config/`](../linux/live-config/)

CLI companion (Alpine):

```bat
build-linux.bat cli
```

## Run

- **VM daily-driver:** 2048 MB+ RAM, boot the Desktop ISO
- **Install:** Calamares from the live desktop onto an empty disk/partition
- **Updates after install:** normal Debian `apt` against bookworm mirrors

## Distro goals

1. Look and feel like **Navine OS**, not stock Debian
2. Work out of the box in VirtualBox/QEMU (Phase A)
3. Install cleanly to disk with Navine bootloader entry (Phase B)
4. Keep Debian package compatibility for real software

See also [`PRODUCTION_ROADMAP.md`](PRODUCTION_ROADMAP.md).
