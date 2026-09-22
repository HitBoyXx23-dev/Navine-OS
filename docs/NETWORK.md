# Navine OS Networking

Navine OS includes a kernel IPv4 client for VirtualBox NAT environments.

## VirtualBox setup

Use `tools/vbox-create.ps1` (run automatically from `build.bat`):

- NIC: Intel PRO/1000 MT Desktop (82540EM)
- Graphics: **VBox VGA** (not VMSVGA)
- Firmware: **BIOS** (EFI off)
- Resolution: 1024x768 (kernel default)
- Attachment: NAT
- Guest IP: DHCP or static `10.0.2.15`
- Gateway: `10.0.2.2`
- DNS: `10.0.2.3`

## Stack components

| Module | Role |
|--------|------|
| `kernel/drivers/e1000.asm` | PCI probe, TX/RX rings |
| `kernel/net/dhcp.asm` | DHCP lease |
| `kernel/net/internet.asm` | ARP, DNS, TCP, HTTP |
| `kernel/net/tls.asm` | TLS 1.2 ClientHello + record parse |
| `kernel/net/websocket.asm` | WebSocket upgrade + text frames |
| `kernel/net/html.asm` | Header skip, Content-Length, text lines |

## Terminal commands

```
ping 8.8.8.8
ifconfig
curl http://example.com
curl https://example.com
```

## HTTPS notes

HTTPS performs TCP connect to port 443, sends TLS ClientHello with SNI, and parses server records. Full AES-GCM decrypt depends on the negotiated cipher; handshake progress is shown in the Browser status bar.

## Discord Gateway

Paste a bot token into `/config/navine.cfg` (`token=` line) via Settings or the installer vault. Discord opens a WebSocket to `gateway.discord.gg` when a token is present.

## Dual TCP slots

- Slot 0 (`0xC000`): HTTP/HTTPS fetches
- Slot 1 (`0xC001`): WebSocket (Discord)

TCP SYN retransmit runs from the PIT timer when handshake stalls.
