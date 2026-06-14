import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    // === User-configurable ===
    property string host: "8.8.8.8"
    property int intervalMs: 5000
    property int timeoutSec: 2

    // === State ===
    property bool enabled: false
    property string latency: "off"
    property bool running: false
    property int errorCount: 0

    // === Refresh timer (only runs when enabled) ===
    Timer {
        id: refreshTimer
        interval: root.intervalMs
        repeat: true
        running: root.enabled
        triggeredOnStart: true
        onTriggered: root.runPing()
    }

    function runPing() {
        if (running) return
        running = true
        // Extract first number after "=" in ping summary (min latency, ~avg)
        const cmd = `ping -c 1 -W ${root.timeoutSec} ${root.host} 2>&1 | grep -oP '=\\s+\\K[0-9.]+' | head -1`
        pingProc.command = ["sh", "-c", cmd]
        pingProc.running = true
    }

    function setEnabled(value) {
        enabled = value
        if (enabled) {
            errorCount = 0
            runPing()
        } else {
            latency = "off"
            errorCount = 0
        }
    }

    function latencyColor() {
        if (!enabled) return Theme.surfaceText
        if (latency === "fail" || latency === "?") return Theme.error
        const ms = parseInt(latency)
        if (isNaN(ms)) return Theme.surfaceText
        if (ms < 50) return Theme.success
        if (ms < 150) return Theme.primary
        return Theme.warning
    }

    Process {
        id: pingProc
        running: false
        stdout: SplitParser {
            onRead: data => {
                const trimmed = data.trim()
                const ms = parseFloat(trimmed)
                if (!isNaN(ms) && ms > 0) {
                    root.latency = Math.round(ms) + " ms"
                    root.errorCount = 0
                }
            }
        }
        onExited: (code, exitStatus) => {
            root.running = false
            if (root.latency === "off") {
                root.errorCount++
                if (root.errorCount >= 5 && root.enabled) {
                    root.setEnabled(false)
                }
            }
        }
    }

    pillClickAction: () => {
        root.setEnabled(!root.enabled)
    }

    horizontalBarPill: Component {
        StyledText {
            text: root.latency
            color: root.latencyColor()
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        }
    }

    verticalBarPill: Component {
        StyledText {
            text: root.latency
            color: root.latencyColor()
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        }
    }
}
