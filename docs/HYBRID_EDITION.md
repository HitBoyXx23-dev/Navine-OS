# Navine OS Hybrid Edition

Lightweight hybrid desktop OS for gaming, coding, and daily use. DOOM is a built-in game app — the desktop UI is clean and modern, not DOOM-themed.

## Quick start

```bat
build.bat
run-vbox.bat
```

Boot flow: **Installer** (pick setup style) → **Desktop** (dock, Spotlight, Mission Control).

## Installer profiles

| Choice | ID | Desktop | Extras |
|--------|-----|---------|--------|
| macOS Style | 0 | Menu bar + dock | Game focus apps |
| Linux Power | 1 | Top panel + launcher | Dev Mode on |
| Windows Style | 2 | Taskbar + search | Classic layout |
| **Hybrid** (default) | 3 | Dock + taskbar + Spotlight | Game + Dev Mode |

## Desktop shortcuts

| Key | Action |
|-----|--------|
| Space | Spotlight |
| M | Mission Control |
| G | Toggle Game Mode (FPS overlay) |
| H | Toggle Dev Mode (npkg ready) |
| F8 | Files vault |
| F10 | Settings |
| F12 | DOOM (game app) |

## Terminal commands

`help` `game` `vault` `browser` `store` `npkg` `download` `downloads` `install` `steam` `epic` `gog` `editor` `monitor` `ping` `ifconfig` `curl` `discord`

## Browser and downloads

The **Navine Browser** (dock/Spotlight → Browser) is a working local browser:

- Address bar with Enter to navigate
- Pages: `home` `apps` `store` `docs` `downloads` `settings` (also accepts `nav://home`)
- `download:<name>` fetches a package from the local repository and **writes it to NavineFS on disk**
- `nav://downloads` lists completed downloads

Repository packages: `grid-pack`, `theme-aurora`, `toolchain-gcc`, `wallpaper-hd`.

Terminal: `download` grabs the default pack, `downloads` reports where they are saved, `install` adds an npkg package.

> Note: Navine OS includes a **live network client** (e1000, DHCP, DNS, TCP, HTTP, TLS handshake, WebSocket). See [`docs/NETWORK.md`](NETWORK.md) for VirtualBox NAT setup and terminal commands (`ping`, `ifconfig`, `curl`).

## Architecture

```
boot/              MBR + stage2 (VESA, paging, kernel load)
kernel/
  link.asm         Monolithic NASM kernel
  fs/              VFS, NavineFS journal, filecache, filetypes
  compat/          PE loader, ELF/DMG, Linux syscall shim
  gaming/          Game library, Vulkan stub
  dev/             npkg package manager
  modes/           Game Mode, Dev Mode
  proc/            Scheduler with priority + game boost
  net/             TCP/IP, TLS, WebSocket, e1000 driver
  drivers/         ATA, PCI, ACPI, USB HID
  desktop/         Installer, dock, Spotlight, Mission Control
  apps/            DOOM, files, terminal, simpleapps panels
compat/            Host C++ scaffolds (build-time reference)
apps/doom/         doomgeneric port
themes/            .navinetheme presets
```

## Phase status (complete)

### Phase 1 — Hybrid shell
- [x] Graphical installer (4 profiles)
- [x] Glass UI, dock, Spotlight, Mission Control
- [x] Native app panels (Settings, Browser, Store, Notes, Calc, Monitor, Editor)
- [x] DOOM disk-loaded game app
- [x] Game Mode / Dev Mode toggles

### Phase 2 — Compatibility
- [x] PE32+ section mapper (`kernel/compat/pe_loader.asm`)
- [x] ELF64 PT_LOAD mapper + Linux syscall translation
- [x] DMG volume mount table + koly/hfs+ probe
- [x] File type registry: `.exe` `.elf` `.dmg` `.AppImage`
- [x] Launcher routes PE/ELF/DMG/NAVAPP
- [x] Vault samples: `sample.exe`, `sample.elf`, `demo.dmg`

### Phase 3 — Gaming
- [x] Game Mode: scheduler boost, FPS overlay, background limiter flag
- [x] Vulkan userspace stub (`vulkan_stub.asm`)
- [x] Game library app (`game_library.asm`)
- [x] USB HID controller stub
- [x] Steam/Epic/GOG terminal launcher hooks

### Phase 4 — Developer
- [x] Dev Mode: npkg integration, scheduler priority boost
- [x] Code editor panel (notes buffer)
- [x] Git status line in Files vault
- [x] `npkg` terminal command (python3, nodejs, rust, gcc)
- [x] Toolchain package list in `kernel/dev/npkg.asm`

### Phase 5 — Production
- [x] VFS + NavineFS with journal sync to disk (LBA 40000+)
- [x] Scheduler: multi-slot processes, priority, game boost
- [x] Network: PCI scan + e1000 probe + stack init
- [x] ACPI battery/AC power stub
- [x] Compositor dirty-region flip
- [x] Syscall MSRs + Linux compat path when ELF loads

## Compatibility roadmaps (next hardware targets)

### Windows EXE
- [x] MZ/PE detect + section map
- [ ] Full Win32 API shim (kernel32/user32)
- [ ] DirectX → Vulkan translation
- [ ] Per-app Wine profiles on disk

### macOS DMG
- [x] Mount table + magic probe
- [ ] UDIF parser
- [ ] HFS+/APFS read-only driver
- [ ] `.app` bundle extraction to NavineFS

### Linux ELF
- [x] ELF64 load + syscall translate
- [ ] AppImage FUSE loop
- [ ] Flatpak-style namespaces (`kernel/security/namespaces.c` host scaffold)

## Performance

| Area | Status |
|------|--------|
| Boot | Installer → desktop in single kernel image |
| RAM | Compositor back-buffer @ 16 MB, minimal services |
| Compositor | Dirty-region row blit |
| Scheduler | Game Mode 2× tick boost + priority classes |
| FS | NavineFS journal + ATA block cache |

## Build outputs

| Output | Purpose |
|--------|---------|
| `build/navine.img` | Raw disk image |
| `build/navine.vdi` | VirtualBox disk |
| `build/Navine OS.iso` | El Torito ISO |
| `build/doom.bin` | DOOM executable |
| `build/system.bin` | C++ dashboard |

## License

Hobby OS project. DOOM WAD is shareware (freeware). Commercial IWADs are not bundled.
