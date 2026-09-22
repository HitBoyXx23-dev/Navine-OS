# Navine OS v1.0.0

First public ISO release aimed at **VM daily-driver testing** (Phase A). Linux Desktop is the recommended edition for real use.

## Downloads

| File | What it is | RAM |
|------|------------|-----|
| `Navine-OS-Linux-Desktop.iso` | Debian 12 XFCE live + Calamares installer | 2 GB+ |
| `Navine-OS-Linux-CLI.iso` | Alpine BusyBox live shell (auto-DHCP) | 512 MB |
| `Navine-OS-Desktop.iso` | Custom kernel graphical desktop (prototype) | 512 MB |
| `Navine-OS-CLI.iso` | Custom kernel fullscreen terminal (prototype) | 512 MB |

Filenames on disk after download may use spaces (`Navine OS Linux Desktop.iso`); release assets use hyphens for compatibility.

## Recommended: Linux Desktop

1. Create a VirtualBox/QEMU VM with **2+ GB RAM**, 20+ GB disk, enable EFI optional.
2. Attach `Navine-OS-Linux-Desktop.iso` and boot.
3. Autologin as `live` into XFCE. NetworkManager handles networking.
4. To install to disk: open **Install Navine OS Linux** (Calamares) on the desktop.

## Linux CLI

Boot BIOS (isolinux). DHCP starts automatically on eth0. Type `navine-help` for commands.

## Custom editions

Hobby / prototype kernels. Expect installer + desktop UI (Desktop) or `navine>` shell (CLI). Package managers, Steam/Epic, and full HTTPS are not production-complete yet — see `docs/PRODUCTION_ROADMAP.md`.

## Verify

```powershell
powershell -File tools\qemu-test.ps1 -Iso "build\Navine OS Linux Desktop.iso" -OutPng build\qemu\linux-desktop.png -BootSeconds 90 -MemoryMB 2048
```

## Source

Repository: https://github.com/NavineDevs/Navine-OS
