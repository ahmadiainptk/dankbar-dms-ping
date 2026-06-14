#!/bin/bash
# install.sh - Installer untuk dankbar-dms-ping
# Usage: ./install.sh

set -e

DMS_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell"
PLUGIN_ID="pingMonitor"
REPO_DIR="$DMS_CONFIG/.repos/local/PingMonitor"
PLUGIN_SYMLINK="$DMS_CONFIG/plugins/$PLUGIN_ID"

echo "🔧 Installing $PLUGIN_ID to DankMaterialShell..."

# === 1. Copy plugin files ===
mkdir -p "$DMS_CONFIG/.repos/local"
rm -rf "$REPO_DIR"
cp -r "$(dirname "$0")/plugin" "$REPO_DIR"
echo "  ✓ Copied to $REPO_DIR"

# === 2. Create symlink ===
mkdir -p "$DMS_CONFIG/plugins"
ln -sf "../.repos/local/PingMonitor" "$PLUGIN_SYMLINK"
echo "  ✓ Symlink: $PLUGIN_SYMLINK"

# === 3. Update plugin_settings.json (enable) ===
SETTINGS_FILE="$DMS_CONFIG/plugin_settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    # Use python to safely update JSON
    python3 -c "
import json, sys
p = '$SETTINGS_FILE'
try:
    with open(p) as f:
        d = json.load(f)
except:
    d = {}
d['$PLUGIN_ID'] = d.get('$PLUGIN_ID', {'enabled': True})
d['$PLUGIN_ID']['enabled'] = True
with open(p, 'w') as f:
    json.dump(d, f, indent=2)
print('  ✓ Updated plugin_settings.json')
"
else
    echo "{\"$PLUGIN_ID\": {\"enabled\": true}}" > "$SETTINGS_FILE"
    echo "  ✓ Created plugin_settings.json"
fi

# === 4. Add to bar rightWidgets (only if not already there) ===
BAR_SETTINGS="$DMS_CONFIG/settings.json"
if [ -f "$BAR_SETTINGS" ]; then
    python3 -c "
import json
p = '$BAR_SETTINGS'
with open(p) as f:
    d = json.load(f)
# Find barConfigs
configs = d.get('barConfigs', [])
if not configs:
    print('  ⚠️  No barConfigs found, add widget manually in bar settings')
    sys.exit(0)
import sys
modified = False
for bc in configs:
    rw = bc.get('rightWidgets', [])
    has = any((isinstance(w, str) and w == '$PLUGIN_ID') or (isinstance(w, dict) and w.get('id') == '$PLUGIN_ID') for w in rw)
    if not has:
        rw.append({'$PLUGIN_ID': {'id': '$PLUGIN_ID', 'enabled': True}}.pop('$PLUGIN_ID'))
        bc['rightWidgets'] = rw
        modified = True
        print(f'  ✓ Added to rightWidgets of screen {bc.get(\"screen\", \"?\")}')
if modified:
    with open(p, 'w') as f:
        json.dump(d, f, indent=2)
else:
    print('  ✓ Already in bar config')
"
fi

# === 5. Restart DMS to load plugin ===
echo ""
echo "🔄 Restarting DMS..."
if command -v dms &>/dev/null; then
    dms restart 2>&1 | tail -2
else
    echo "  ⚠️  dms not in PATH, manually restart with: dms restart"
fi

echo ""
echo "✅ Install selesai!"
echo ""
echo "🧪 Test:"
echo "  - Lihat Dank Bar (kanan): widget 'off' harusnya muncul"
echo "  - Click widget: mulai ping, text jadi 'XX ms'"
echo "  - Tunggu 5 detik: latency update otomatis"
echo ""
echo "⚙️  Customize host/interval/timeout: klik kanan bar → Settings → pilih widget"
echo "🗑️  Uninstall: $0 uninstall"
