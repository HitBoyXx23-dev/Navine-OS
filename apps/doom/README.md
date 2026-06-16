# DOOM on Navine OS

Port of [doomgeneric](https://github.com/ozkl/doomgeneric) with [Squashware](https://github.com/fragglet/squashware) IWAD support.

## WAD profiles (`apps/doom/wad.config`)

| Profile | Source | Size |
|---------|--------|------|
| `squashware` | [Squashware v1.3](https://github.com/fragglet/squashware) full shareware | ~1.7 MB |
| `squashware-1lev` | Squashware E1M1 only | ~700 KB |
| `squashware-silent` | Squashware without music/SFX | ~1.4 MB |
| `custom` | Your own WAD in `apps/doom/wads/` | varies |

`build.bat` downloads Squashware automatically when network is available.

## Custom IWADs (DOOM II, etc.)

If you own the games, you may use IWADs from your collection:

1. Copy `doom1.wad`, `DOOM.WAD`, or `doom2.wad` to `apps/doom/wads/`
2. Set `apps/doom/wad.config` to `custom`
3. Run `build.bat`

Navine OS does not download commercial IWADs. Repositories such as [All-Doom-IWADS](https://github.com/admint314/All-Doom-IWADS) must be cloned manually; only use files you legally own.

## Run

Press **F10** on the Navine OS desktop.

## Disk layout

| LBA | Content |
|-----|---------|
| 0 | MBR / Stage 1 |
| 2 | Stage 2 |
| 20 | Kernel |
| 8192 | doom.bin |
| 9216 | doom1.wad |

## Controls

| Key | Action |
|-----|--------|
| F10 | Launch DOOM |
| WASD / Arrows | Move |
| Ctrl | Fire |
| Space | Use |
| Esc | Menu |
