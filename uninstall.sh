#!/bin/bash
# uninstall.sh - Hapus dankbar-dms-ping
# Usage: ./uninstall.sh

set -e

DMS_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell"
PLUGIN_ID="pingMonitor"
REPO_DIR="$DMS_CONFIG/.repos/local/PingMonitor"
PLUGIN_SYMLINK="$DMS_CONFIG/plugins/$PLUGIN_ID"

echo "🗑️  Removing $PLUGIN_ID..."

# Remove symlink
rm -f "$PLUGIN_SYMLINK"
echo "  ✓ Removed symlink"

# Remove plugin files
rm -rf "$REPO_DIR"
echo "  ✓ Removed $REPO_DIR"

# Remove from plugin_settings.json
SETTINGS_FILE="$DMS_CONFIG/plugin_settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    python3 -c "
import json
p = '$SETTINGS_FILE'
with open(p) as f:
    d = json.load(f)
d.pop('$PLUGIN_ID', None)
with open(p, 'w') as f:
    json.dump(d, f, indent=2)
"
    echo "  ✓ Updated plugin_settings.json"
fi

# Remove from bar settings
BAR_SETTINGS="$DMS_CONFIG/settings.json"
if [ -f "$BAR_SETTINGS" ]; then
    python3 -c "
import json
p = '$BAR_SETTINGS'
with open(p) as f:
    d = json.load(f)
modified = False
for bc in d.get('barConfigs', []):
    rw = bc.get('rightWidgets', [])
    new_rw = [w for w in rw if not (isinstance(w, str) and w == '$PLUGIN_ID') or (isinstance(w, dict) and w.get('id') == '$PLUGIN_ID')]
    if len(new_rw) != len(rw):
        bc['rightWidgets'] = new_rw
        modified = True
if modified:
    with open(p, 'w') as f:
        json.dump(d, f, indent=2)
    print('  ✓ Removed from bar settings')
"
fi

# Restart DMS
if command -v dms &>/dev/null; then
    dms restart 2>&1 | tail -1
fi

echo ""
echo "✅ Uninstall selesai."
