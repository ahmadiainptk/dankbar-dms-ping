import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root

    SettingsRow {
        label: "Host"
        TextField {
            placeholderText: "8.8.8.8"
            text: (widgetData && widgetData.host) || "8.8.8.8"
            onTextChanged: {
                if (widgetData) widgetData.host = text
            }
        }
    }

    SettingsRow {
        label: "Interval (seconds)"
        SpinBox {
            from: 1
            to: 60
            value: Math.max(1, ((widgetData && widgetData.intervalMs) || 5000) / 1000)
            onValueChanged: {
                if (widgetData) widgetData.intervalMs = value * 1000
            }
        }
    }

    SettingsRow {
        label: "Timeout (seconds)"
        SpinBox {
            from: 1
            to: 10
            value: (widgetData && widgetData.timeoutSec) || 2
            onValueChanged: {
                if (widgetData) widgetData.timeoutSec = value
            }
        }
    }
}
