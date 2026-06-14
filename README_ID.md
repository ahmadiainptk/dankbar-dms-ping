# dankbar-dms-ping

Widget **DankMaterialShell** (DMS) yang ping host sesuai permintaan dan tampilkan latency di Dank Bar. Click untuk toggle, klik kanan untuk ganti host, warna berdasarkan kualitas latency.

> 🇬🇧 **English version?** See [README.md](README.md)

## ✨ Fitur

- **Click to toggle** — Start/stop ping dengan satu click
- **Real-time latency** — Update setiap N detik (configurable)
- **Warna otomatis**:
  - 🟢 Hijau: < 50ms (sangat cepat)
  - 🔵 Primary: 50-150ms (baik)
  - 🟠 Warning: > 150ms (lambat)
  - 🔴 Error: timeout/gagal
- **Persistent** — Auto-disable setelah 5× gagal berturut
- **Configurable** — Host, interval, timeout via klik kanan → Settings
- **Plugin lokal** — Gak butuh dependency external, gak perlu `git clone`

## 📸 Preview

```
[ ... bar widgets ... ]   off          ← idle, click untuk mulai
[ ... bar widgets ... ]   33 ms        ← pinging, latency update
[ ... bar widgets ... ]   150 ms       ← lebih lambat
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

- `DankMaterialShell` terinstall & running
- `bash`, `python3` (untuk installer)
- `ping` (iputils)
- `grep` dengan PCRE support (`grep -P`)

## 🚀 Install

```bash
git clone https://github.com/ahmadiainptk/dankbar-dms-ping.git
cd dankbar-dms-ping
chmod +x install.sh uninstall.sh
./install.sh
```

Installer akan:
1. Copy plugin ke `~/.config/DankMaterialShell/.repos/local/PingMonitor/`
2. Bikin symlink di `~/.config/DankMaterialShell/plugins/pingMonitor`
3. Enable plugin di `plugin_settings.json`
4. Tambah ke rightWidgets bar default
5. Restart DMS

## 🧪 Test

1. Lihat Dank Bar lo (section kanan by default)
2. Widget show **"off"** awalnya
3. **Click** widget → jadi **"33 ms"** (atau sekitar itu)
4. Tunggu 5s → update otomatis
5. **Click lagi** → stop, balik **"off"**

## 🗑️ Uninstall

```bash
./uninstall.sh
```

## ⚙️ Konfigurasi

Klik kanan Dank Bar → **Settings** → click widget → adjust:
- **Host**: IP atau hostname untuk ping (default: `8.8.8.8`)
- **Interval**: Detik antara ping (default: 5)
- **Timeout**: Detik sebelum ping dianggap gagal (default: 2)

## 🔧 Cara Kerja

1. `PluginComponent` adalah base class untuk DMS plugin
2. Callback `pillClickAction` toggle state `enabled`
3. `Timer` trigger `runPing()` setiap N detik saat enabled
4. `Quickshell.Io.Process` run `ping -c 1 -W T host | grep -oP '=\s+\K[0-9.]+'` untuk ekstrak latency
5. `SplitParser` baca stdout line-by-line, update property `latency`
6. Component `horizontalBarPill` / `verticalBarPill` render text dengan warna sesuai latency

Parser ekstrak angka pertama setelah `=` di baris summary ping:
```
rtt min/avg/max/mdev = 33.853/33.853/33.853/0.000 ms
                          ^^^^^^^
                          diambil sebagai latency
```

## 📁 Struktur Repo

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

**Widget gak muncul di bar**
- Run `dms ipc plugins list` — harusnya ada `pingMonitor [loaded]`
- Cek `~/.config/DankMaterialShell/plugins/pingMonitor` symlink-nya valid
- Coba `dms restart` manual

**Latency "0 ms" atau gak update**
- Cek `journalctl --user -u dms | grep pingMonitor` untuk error
- Verify `ping -c 1 8.8.8.8` jalan di terminal
- Cek setting host (default `8.8.8.8` butuh internet)

**"fail" muncul terus**
- Host unreachable atau `ping` gak terinstall
- Cek `which ping` ada output
- Coba host lain (misal `1.1.1.1`)

## 🤝 Contributing

PR welcome! Beberapa ide:
- Chart/graph widget yang show latency over time
- Multi-host comparison (ping 3 host sekaligus)
- Traceroute mode
- TCP port ping代替 ICMP

## 📜 License

MIT License — lihat [LICENSE](LICENSE).

## ⚠️ Disclaimer

Widget ini pakai ICMP ping yang butuh `CAP_NET_RAW` atau root. Untuk unprivileged ping (tanpa root), pakai TCP ping di port 80/443.

## 👤 Author

**ahmadiainptk** — IT Admin di IAIN Pontianak
- GitHub: [@ahmadiainptk](https://github.com/ahmadiainptk)
- Email: ahmad.iainptk@gmail.com

## 🔗 Project Lain

- [wifi-fix-ax211](https://github.com/ahmadiainptk/wifi-fix-ax211) — WiFi auto-recovery
- [btrfs-snapper-alert](https://github.com/ahmadiainptk/btrfs-snapper-alert) — Monitor snapshot snapper
- [dm-switch](https://github.com/ahmadiainptk/dm-switch) — Toggle Greetd/SDDM
