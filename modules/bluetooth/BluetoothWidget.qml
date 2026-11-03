import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../colors/color.scss"

RowLayout {
    id: root

    property string connectedDevice: "None"
    property bool isConnected: false

    spacing: 6

    Process {
        id: btInfoProcess

        // Pulls the names of all currently connected devices
        command: ["sh", "-c", "bluetoothctl devices Connected | cut -d ' ' -f 3-"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                var output = this.text.trim();
                if (output !== "") {
                    // Takes the first connected device if there are multiple lines
                    root.connectedDevice = output.split("\n")[0];
                    root.isConnected = true;
                } else {
                    root.connectedDevice = "None";
                    root.isConnected = false;
                }
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            btInfoProcess.running = true; // Signals Quickshell to start the process execution
        }
    }

    // --- Visual Layout ---
    RowLayout {
        spacing: 1

        Text {
            text: root.isConnected ? "" : "󰂲"
            color: root.isConnected ? "#9ccfd8" : "#6272a4"
            font.pixelSize: 12
        }

        Text {
            text: root.connectedDevice
            color: root.isConnected ? "#9ccfd8" : "#6272a4"
            font.pixelSize: 12
            elide: Text.ElideRight
            Layout.maximumWidth: 120

            font {
                family: "JetBrainsMono Nerd Font Propo"
                weight: 500
            }
        }
    }
}