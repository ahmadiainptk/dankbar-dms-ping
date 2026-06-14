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

    // === Log buffer (last N entries) ===
    property var logEntries: []
    readonly property int maxLogEntries: 15

    function appendLog(ok, value) {
        const entry = {
            ts: new Date().toLocaleTimeString(Qt.locale(), "HH:mm:ss"),
            host: root.host,
            latency: value,
            ok: ok
        }
        const newLog = root.logEntries.slice()
        newLog.unshift(entry)
        if (newLog.length > root.maxLogEntries) {
            newLog.length = root.maxLogEntries
        }
        root.logEntries = newLog
    }

    // === Refresh timer ===
    Timer {
        interval: root.intervalMs
        repeat: true
        running: root.enabled
        triggeredOnStart: true
        onTriggered: root.runPing()
    }

    function runPing() {
        if (running) return
        running = true
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
                    root.appendLog(true, root.latency)
                    root.errorCount = 0
                }
            }
        }
        onExited: (code) => {
            root.running = false
            if (code !== 0) {
                root.latency = "fail"
                root.appendLog(false, "fail")
                root.errorCount++
                if (root.errorCount >= 5 && root.enabled) {
                    root.setEnabled(false)
                }
            }
        }
    }

    // === Right click: toggle ping ===
    pillRightClickAction: () => {
        root.setEnabled(!root.enabled)
    }

    // === Left click: auto-opens popout (no pillClickAction needed) ===

    function latencyColorMs(ms) {
        if (isNaN(ms)) return Theme.surfaceText
        if (ms < 50) return Theme.success
        if (ms < 150) return Theme.primary
        return Theme.warning
    }

    // === Popout content ===
    popoutContent: Component {
        PopoutComponent {
            headerText: "Ping Monitor"
            detailsText: root.enabled ? `Pinging ${root.host} • ${root.latency}` : `Idle • last: ${root.latency}`
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                // === Status + Stop button ===
                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    StyledRect {
                        width: (parent.width - Theme.spacingM) * 0.55
                        height: 56
                        radius: Theme.cornerRadius
                        color: Theme.nestedSurface
                        border.width: 0

                        Column {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            spacing: 2

                            StyledText {
                                text: "Status"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceTextMedium
                            }
                            StyledText {
                                text: root.enabled ? root.latency : "off"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Bold
                                color: root.enabled ? root.latencyColor() : Theme.surfaceText
                            }
                        }
                    }

                    StyledRect {
                        width: (parent.width - Theme.spacingM) * 0.45
                        height: 56
                        radius: Theme.cornerRadius
                        color: stopArea.containsMouse ? Theme.errorHover : Theme.nestedSurface
                        border.width: 0

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingS

                            DankIcon {
                                name: "stop"
                                size: Theme.iconSize - 4
                                color: stopArea.containsMouse ? Theme.error : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            StyledText {
                                text: "Stop"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: stopArea.containsMouse ? Theme.error : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: stopArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.setEnabled(false)
                        }
                    }
                }

                // === Host input ===
                StyledRect {
                    width: parent.width
                    height: 70
                    radius: Theme.cornerRadius
                    color: Theme.nestedSurface
                    border.width: 0

                    Column {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingXS

                        StyledText {
                            text: "Host"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceTextMedium
                        }

                        Row {
                            width: parent.width
                            spacing: Theme.spacingS

                            DankTextField {
                                id: hostInput
                                width: parent.width - applyBtn.width - Theme.spacingS
                                text: root.host
                                onAccepted: applyBtn.clicked()
                            }

                            StyledRect {
                                id: applyBtn
                                width: 70
                                height: 28
                                radius: Theme.cornerRadius
                                color: applyArea.containsMouse ? Theme.primaryHover : Theme.primary
                                border.width: 0

                                StyledText {
                                    anchors.centerIn: parent
                                    text: "Apply"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.primaryText
                                }

                                MouseArea {
                                    id: applyArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const newHost = hostInput.text.trim()
                                        if (newHost.length > 0 && newHost !== root.host) {
                                            root.host = newHost
                                            if (root.enabled) {
                                                root.errorCount = 0
                                                root.runPing()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // === Log ===
                StyledRect {
                    width: parent.width
                    height: 220
                    radius: Theme.cornerRadius
                    color: Theme.nestedSurface
                    border.width: 0

                    Column {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingXS

                        Row {
                            width: parent.width
                            StyledText {
                                text: "Log"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceTextMedium
                                font.weight: Font.Medium
                            }
                            Item { width: 1; height: 1 }
                            StyledText {
                                text: "Clear"
                                font.pixelSize: Theme.fontSizeSmall
                                color: clearArea.containsMouse ? Theme.error : Theme.surfaceTextMedium
                                MouseArea {
                                    id: clearArea
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.logEntries = []
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: parent.height - 22

                            StyledText {
                                anchors.centerIn: parent
                                text: "No entries yet. Right-click widget to start pinging."
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceTextMedium
                                visible: root.logEntries.length === 0
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            ListView {
                                anchors.fill: parent
                                clip: true
                                spacing: 2
                                model: root.logEntries
                                visible: root.logEntries.length > 0
                                delegate: Row {
                                    width: ListView.view.width
                                    spacing: Theme.spacingS

                                    StyledText {
                                        text: modelData.ts
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceTextMedium
                                        width: 56
                                    }
                                    StyledText {
                                        text: modelData.host
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceTextMedium
                                        elide: Text.ElideRight
                                        width: 100
                                    }
                                    StyledText {
                                        text: modelData.latency
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Medium
                                        color: {
                                            if (!modelData.ok) return Theme.error
                                            const ms = parseInt(modelData.latency)
                                            if (isNaN(ms)) return Theme.surfaceText
                                            return root.latencyColorMs(ms)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // === Pill UI (horizontal) ===
    horizontalBarPill: Component {
        StyledText {
            text: root.latency
            color: root.latencyColor()
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        }
    }

    // === Pill UI (vertical) ===
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
