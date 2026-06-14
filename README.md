# dankbar-dms-ping

A **DankMaterialShell** (DMS) bar widget that pings a host on demand and displays the latency in the Dank Bar. Click to toggle, right-click to cycle host, color-coded by latency quality.

> 🇮🇩 **Bahasa Indonesia?** Lihat [README_ID.md](README_ID.md)

## ✨ Features

- **Click left** — Open popout window with controls
- **Click right** — Toggle ping on/off
- **Real-time latency display** in the Dank Bar — updates every N seconds
- **Color-coded**:
  - 🟢 Green: < 50ms (excellent)
  - 🔵 Primary: 50-150ms (good)
  - 🟠 Warning: > 150ms (slow)
  - 🔴 Error: timeout/fail
- **Persistent** — Auto-disable after 5 consecutive failures
- **Configurable** — Host, interval, timeout via right-click → Settings
- **Popout window** (left click) contains:
  - Live status with color-coded latency
  - **Stop button** — instantly stops the ping loop
  - **Host input** with Apply button — change target host on the fly
  - **Log of last 15 entries** — timestamp, host, latency, color-coded
  - **Clear log** button
- **Local plugin** — No external dependencies, no `git clone` required

## 🎮 Controls

| Action | Result |
|--------|--------|
| **Left click** | Open popout (click again to close) |
| **Right click** | Toggle ping on/off |
| **Klik kiri** (ID) | Buka popout (klik lagi untuk tutup) |
| **Klik kanan** (ID) | Toggle ping on/off |

## 📸 Preview

```
[ ... bar widgets ... ]   off          ← idle, click to start
[ ... bar widgets ... ]   33 ms        ← pinging, latency updating
[ ... bar widgets ... ]   150 ms       ← slower
[ ... bar widgets ... ]   fail         ← ping timeout
```

## 🖥️ Tested on

| Item | Detail |
|------|--------|
| **OS** | CachyOS (Arch-based) |
| **Desktop** | Hyprland (Wayland) |
| **Shell** | DankMaterialShell 1.4.6 (Quickshell-based) |
| **Bar** | Dank Bar |

## 📦 Requirements

- `DankMaterialShell` installed and running
- `bash`, `python3` (for installer)
- `ping` (iputils)
- `grep` with PCRE support (`grep -P`)

## 🚀 Install

```bash
git clone https://github.com/ahmadiainptk/dankbar-dms-ping.git
cd dankbar-dms-ping
chmod +x install.sh uninstall.sh
./install.sh
```

The installer will:
1. Copy plugin to `~/.config/DankMaterialShell/.repos/local/PingMonitor/`
2. Create symlink at `~/.config/DankMaterialShell/plugins/pingMonitor`
3. Enable plugin in `plugin_settings.json`
4. Add to rightWidgets of default bar
5. Restart DMS

## 🧪 Test

1. Look at your Dank Bar (right section by default)
2. Widget shows **"off"** initially
3. **Right-click** the widget → starts ping, becomes **"33 ms"** (or similar)
4. Wait 5s → updates automatically
5. **Left-click** the widget → opens popout with status, Stop button, host input, and log
6. In popout, click **Stop** → ping stops, widget shows **"off"** again
7. In popout, type new host (e.g. `1.1.1.1`) and click **Apply** → ping switches to new host

## 🗑️ Uninstall

```bash
./uninstall.sh
```

## ⚙️ Configuration

Right-click the Dank Bar → **Settings** → click the widget → adjust:
- **Host**: IP or hostname to ping (default: `8.8.8.8`)
- **Interval**: Seconds between pings (default: 5)
- **Timeout**: Seconds before ping fails (default: 2)

## 🔧 How It Works

1. `PluginComponent` is the base class for DMS plugins
2. `popoutContent` Component (auto-wired by DMS) creates a popout when defined
3. `pillRightClickAction` toggles `enabled` state (right-click handler)
4. Left-click is auto-handled by DMS — opens the popout
5. `Timer` triggers `runPing()` every N seconds when enabled
6. `Quickshell.Io.Process` runs `ping -c 1 -W T host | grep -oP '=\s+\K[0-9.]+'` to extract latency
7. `SplitParser` reads stdout line-by-line, updates `latency` property and `logEntries`
8. `horizontalBarPill` / `verticalBarPill` components render the text with color based on latency
9. `onExited` checks exit code: 0 = success, != 0 = mark as "fail" (red) and auto-disable after 5 fails
10. Popout window (PopoutComponent) shows live status, Stop button (sets `enabled=false`), Host input + Apply (changes `host` property and re-runs ping), and a 15-entry rolling log

The parser extracts the first number after `=` in ping's summary line:
```
rtt min/avg/max/mdev = 33.853/33.853/33.853/0.000 ms
                          ^^^^^^^
                          extracted as latency
```

## 📁 Repo Structure

```
dankbar-dms-ping/
├── README.md           (English)
├── README_ID.md        (Bahasa Indonesia)
├── LICENSE
├── install.sh
├── uninstall.sh
└── plugin/
    ├── plugin.json
    ├── PingMonitorWidget.qml
    └── PingMonitorSettings.qml
```

## 🔍 Troubleshooting

**Widget doesn't appear in bar**
- Run `dms ipc plugins list` — should show `pingMonitor [loaded]`
- Check `~/.config/DankMaterialShell/plugins/pingMonitor` is a valid symlink
- Try `dms restart` manually

**Latency shows "0 ms" or never updates**
- Check `journalctl --user -u dms | grep pingMonitor` for errors
- Verify `ping -c 1 8.8.8.8` works from terminal
- Check host setting (default `8.8.8.8` requires internet)

**"fail" appears repeatedly**
- Host unreachable or `ping` not installed
- Check `which ping` returns a path
- Try different host (e.g. `1.1.1.1`)

## 🤝 Contributing

PRs welcome! Some ideas:
- Chart/graph widget showing latency over time
- Multi-host comparison (ping 3 hosts at once)
- Traceroute mode
- TCP port ping instead of ICMP (no root needed)

## 📜 License

MIT License — see [LICENSE](LICENSE).

## ⚠️ Disclaimer

This widget uses ICMP ping which requires `CAP_NET_RAW` or root. For unprivileged ping (no root), use TCP ping on port 80/443 instead.

## 👤 Author

**ahmadiainptk** — IT Admin at IAIN Pontianak
- GitHub: [@ahmadiainptk](https://github.com/ahmadiainptk)
- Email: ahmad.iainptk@gmail.com

## 🔗 Related Projects

- [wifi-fix-ax211](https://github.com/ahmadiainptk/wifi-fix-ax211) — WiFi auto-recovery
- [btrfs-snapper-alert](https://github.com/ahmadiainptk/btrfs-snapper-alert) — Snapper snapshot monitor
- [dm-switch](https://github.com/ahmadiainptk/dm-switch) — Greetd/SDDM toggle
