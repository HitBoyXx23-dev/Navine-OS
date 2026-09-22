# Navine OS Production Roadmap

Goal: **A** first (daily-driver in VirtualBox/QEMU for testing), then **B** (real alternative OS on hardware).
Strategy: **Linux editions first**, then harden the custom kernel Desktop/CLI.

## Editions

| Product | Near-term role |
|---------|----------------|
| Navine OS Linux Desktop | Primary daily-driver path (Debian XFCE) |
| Navine OS Linux CLI | Lightweight terminal live + recovery shell |
| Navine OS Desktop | Custom graphical OS (prototype -> real later) |
| Navine OS CLI | Custom fullscreen shell (honest feature set) |

## Phase A — VM daily-driver (testing)

Done when you can boot each ISO in VirtualBox/QEMU, use the system for a session, and reboot cleanly.

### Linux Desktop
- Boots to XFCE with NetworkManager and Firefox
- Calamares installer launches (install-to-disk tested in a second VM disk)
- QEMU/VBox defaults: >= 2048 MB RAM
- Build fails hard on broken live-build output
- Path-agnostic `build-linux.bat`

### Linux CLI
- Auto DHCP on `eth0` at boot
- Serial + VGA console usable
- Document BIOS-only boot (UEFI in Phase B)

### Custom Desktop / CLI
- Stable boot in VMs (installer or CLI shell)
- Honest UI: no fake “working” network/package claims
- Live `ifconfig` from DHCP state
- Known stubs called out in docs, not sold as finished features

## Phase B — Real alternative OS

Done when a user can install to disk on typical UEFI PCs and use it as a secondary OS.

### Linux Desktop
- Verified BIOS + UEFI boot
- Branded Calamares that preserves Navine identity after install
- Security mirrors enabled; apt updates work
- Optional live persistence boot entry
- Wi-Fi / audio via Debian firmware packages on supported hardware

### Linux CLI
- UEFI El Torito or GRUB boot
- Optional install-to-disk or documented recovery-only scope

### Custom kernel
- Real install-to-disk (partition + NavineFS persistence verified)
- Process model beyond cooperative UI loop
- TLS with real crypto (or drop HTTPS claims)
- Real package format for `npkg` (or remove from help)
- AHCI/USB input path; expand beyond VirtualBox e1000 NAT niche

## Non-goals (until later)

- Full Windows/macOS/Linux app compatibility
- Vulkan / Steam / Epic / Discord as production clients
- Competing with mainstream distros on every laptop SKU

## Verify checklist

```bat
build.bat
build-linux.bat all
```

```powershell
powershell -File tools\qemu-test.ps1 -Iso "build\Navine OS Desktop.iso" -OutPng build\qemu\desktop.png -BootSeconds 25 -MemoryMB 512
powershell -File tools\qemu-test.ps1 -Iso "build\Navine OS CLI.iso" -OutPng build\qemu\cli.png -BootSeconds 20 -MemoryMB 512
powershell -File tools\qemu-test.ps1 -Iso "build\Navine OS Linux CLI.iso" -OutPng build\qemu\linux-cli.png -BootSeconds 25 -MemoryMB 512 -SerialLog build\qemu\linux-cli-serial.log
powershell -File tools\qemu-test.ps1 -Iso "build\Navine OS Linux Desktop.iso" -OutPng build\qemu\linux-desktop.png -BootSeconds 90 -MemoryMB 2048
```

VirtualBox: create a VM with 2+ GB RAM for Linux Desktop; attach the ISO; for Phase B add a second empty VDI and run Install Navine OS Linux.
