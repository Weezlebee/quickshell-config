import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../theme"

RowLayout {
    id: root
    spacing: 4

    property string ssid: ""
    property int rssi: -100
    property bool isConnected: false

    // Periodically run iwctl to check connection details
    Process {
        id: iwctlProc
        command: ["iwctl", "station", "wlan0", "show"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (data.includes("Connected network")) {
                    let parts = data.split("Connected network");
                    if (parts.length > 1) {
                        root.ssid = parts[1].trim();
                        root.isConnected = true;
                    }
                }
                if (data.includes("RSSI")) {
                    let parts = data.split("RSSI");
                    if (parts.length > 1) {
                        let val = parseInt(parts[1].replace("dBm", "").trim());
                        if (!isNaN(val)) root.rssi = val;
                    }
                }
                if (data.includes("State") && data.includes("disconnected")) {
                    root.isConnected = false;
                }
            }
        }
    }

    // Refresh every 3 seconds
    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: iwctlProc.running = true
    }

    readonly property string icon: {
        if (!root.isConnected) return "\uF092D"

        let tier = root.rssi >= -55 ? 4
                 : root.rssi >= -67 ? 3 
                 : root.rssi >= -80 ? 2
                 : 1

        return String.fromCodePoint(0xF091F + (tier - 1) * 3)
    }

    Text {
        text: root.icon
        color: root.isConnected ? Theme.rose : "#524f67"

        font {
            family: "JetBrainsMono Nerd Font Propo"
            pixelSize: 13
        }
    }

    Text {
        text: root.isConnected ? (root.ssid || "Connected") : "Disconnected"
        color: Theme.text

        font {
            family: "JetBrainsMono Nerd Font Propo"
            weight: 650
        }
    }
}