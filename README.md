# Navine OS

Navine OS ships four bootable ISOs: custom Desktop/CLI kernels, plus Linux Desktop/CLI editions.

Roadmap: [Production plan (VM daily-driver → real OS)](docs/PRODUCTION_ROADMAP.md)

**DOOM** is included as a real built-in game on the custom Desktop edition. The desktop UI is clean and modern — not DOOM-themed.

## Editions

| Edition | ISO | Description |
|---------|-----|-------------|
| Navine OS Desktop | `build/Navine OS Desktop.iso` | Custom kernel with graphical installer and desktop |
| Navine OS CLI | `build/Navine OS CLI.iso` | Custom kernel with fullscreen terminal shell |
| Navine OS Linux Desktop | `build/Navine OS Linux Desktop.iso` | Debian 12 live XFCE desktop (primary daily-driver path) |
| Navine OS Linux CLI | `build/Navine OS Linux CLI.iso` | Alpine live terminal (BusyBox shell) |

## Requirements

- [NASM](https://www.nasm.us/) 2.15+ — custom edition
- [Python](https://www.python.org/) 3.8+ with Pillow — wallpaper, font, and ISO tooling
- [WSL](https://learn.microsoft.com/windows/wsl/install) with `live-build`, `debootstrap`, `xorriso` — Linux edition (Desktop build as root: `wsl -u root`)
- [VirtualBox](https://www.virtualbox.org/) for the recommended test VM
- [QEMU](https://www.qemu.org/) (optional) for headless boot verification

## Build and run

Custom editions:

```bat
build.bat
```

Produces `build/Navine OS Desktop.iso` and `build/Navine OS CLI.iso`.

Linux editions:

```bat
build-linux.bat all
build-linux.bat desktop
build-linux.bat cli
```

## Verifying an ISO

```powershell
powershell -File tools\qemu-test.ps1 -Iso "build\Navine OS Desktop.iso" -OutPng build\qemu\desktop.png -BootSeconds 25 -MemoryMB 512
powershell -File tools\qemu-test.ps1 -Iso "build\Navine OS CLI.iso" -OutPng build\qemu\cli.png -BootSeconds 20 -MemoryMB 512
powershell -File tools\qemu-test.ps1 -Iso "build\Navine OS Linux CLI.iso" -OutPng build\qemu\linux-cli.png -BootSeconds 25 -MemoryMB 512 -SerialLog build\qemu\linux-cli-serial.log
powershell -File tools\qemu-test.ps1 -Iso "build\Navine OS Linux Desktop.iso" -OutPng build\qemu\linux-desktop.png -BootSeconds 90 -MemoryMB 2048
```

Custom Desktop should show the graphical installer with a working mouse. Custom CLI shows a fullscreen `navine>` shell. Linux Desktop needs **2 GB RAM** and ~90s to reach XFCE. Linux CLI should auto-DHCP on eth0.

## First boot (custom Desktop)

1. Graphical **installer** — choose macOS, Linux, Windows, or **Hybrid** (recommended).
2. Complete setup → **desktop** with dock, menubar, Spotlight (Space), Mission Control (M).
3. Toggle **Game Mode** (G) or **Dev Mode** (H) from the keyboard.

## Documentation

- [Production roadmap](docs/PRODUCTION_ROADMAP.md)
- [Linux edition](docs/LINUX_EDITION.md)
- [Hybrid Edition architecture](docs/HYBRID_EDITION.md)
- [Themes](themes/README.md)
- [DOOM app](apps/doom/README.md)

## Project layout

| Path | Description |
|------|-------------|
| `boot/` | Bootloader (MBR, stage2, VESA) |
| `kernel/` | NASM monolithic kernel |
| `linux/` | Navine OS Linux edition build scripts |
| `compat/` | PE, ELF, DMG host scaffolds |
| `apps/doom/` | doomgeneric port |
| `themes/` | `.navinetheme` presets |
| `tools/` | VirtualBox / QEMU / ISO scripts |

## License

See repository license file.
