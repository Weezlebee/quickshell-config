pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"
import "./"

ColumnLayout {
    id: networkPage
    spacing: 14

    property bool wifiEnabled: true
    property var wifiNetworks: []
    property string activeSsid: ""
    property int ethernetDeviceCount: 0
    property int ethernetConnectedCount: 0
    property bool isScanning: false

    function refresh() {
        deviceReader.running = true;
        scanReader.running = true;
    }

    function setWifiEnabled(enabled) {
        let cmd = Qt.createQmlObject('import Quickshell.Io; Process {}', networkPage);
        cmd.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"];
        cmd.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: deviceReader
        command: ["bash", "-c", "nmcli -t -f DEVICE,TYPE,STATE device"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');
                let ethTotal = 0, ethConnected = 0;
                for (const line of lines) {
                    const parts = line.split(':');
                    if (parts[1] === "ethernet") {
                        ethTotal++;
                        if (parts[2] === "connected") ethConnected++;
                    }
                }
                networkPage.ethernetDeviceCount = ethTotal;
                networkPage.ethernetConnectedCount = ethConnected;
            }
        }
    }

    Process {
        id: scanReader
        command: ["bash", "-c", "nmcli -t -f ACTIVE,SSID,SECURITY device wifi list"]
        onRunningChanged: networkPage.isScanning = running

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n');
                const seen = {};
                let active = "";
                for (const line of lines) {
                    if (!line) continue;
                    const parts = line.split(':');
                    const isActive = parts[0] === "yes";
                    const ssid = parts[1] || "";
                    const secure = (parts[2] || "").trim() !== "" && parts[2] !== "--";
                    if (!ssid) continue;
                    if (isActive) active = ssid;

                    if (!seen[ssid] || isActive) {
                        seen[ssid] = { ssid: ssid, secure: secure };
                    }
                }
                networkPage.activeSsid = active;
                networkPage.wifiNetworks = Object.values(seen);
            }
        }
    }

    // --- Wireless toggle ---
    Rectangle {
        Layout.fillWidth: true
        height: 56
        radius: 12
        color: Theme.bg1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text { text: "Wi-Fi enabled"; color: Theme.text; font.bold: true; font.pixelSize: 14 }
                Text { text: "Toggle wireless networking"; color: Theme.subText; font.pixelSize: 11 }
            }

            ToggleSwitch {
                checked: networkPage.wifiEnabled
                onToggled: (v) => { networkPage.wifiEnabled = v; networkPage.setWifiEnabled(v); }
            }
        }
    }

    // --- Ethernet ---
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 90
        radius: 12
        color: Theme.bg1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 6

            Text { text: "Ethernet"; color: Theme.text; font.bold: true; font.pixelSize: 14 }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Total devices"; color: Theme.subText; Layout.fillWidth: true }
                Text { text: networkPage.ethernetDeviceCount; color: Theme.text }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Connected"; color: Theme.subText; Layout.fillWidth: true }
                Text { text: networkPage.ethernetConnectedCount; color: Theme.text }
            }
        }
    }

    // --- Wireless networks list ---
    Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: Theme.bg1
        implicitHeight: netListCol.implicitHeight + 32

        ColumnLayout {
            id: netListCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Networks (" + networkPage.wifiNetworks.length + ")"; color: Theme.text; font.bold: true; font.pixelSize: 14; Layout.fillWidth: true }
                Text {
                    text: networkPage.isScanning ? "scanning..." : "refresh"
                    color: networkPage.isScanning ? Theme.subText : Theme.highlight
                    font.pixelSize: 12
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: !networkPage.isScanning
                        onClicked: networkPage.refresh()
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                implicitHeight: contentHeight
                interactive: false
                clip: true
                spacing: 4
                model: networkPage.wifiNetworks

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 44
                    radius: 8
                    color: modelData.ssid === networkPage.activeSsid ? Theme.bg2 : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12

                        Text {
                            text: modelData.ssid
                            color: modelData.ssid === networkPage.activeSsid ? Theme.highlight : Theme.text
                            font.bold: modelData.ssid === networkPage.activeSsid
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.ssid === networkPage.activeSsid ? "connected" : (modelData.secure ? "secured" : "open")
                            color: Theme.subText
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }

    Item { Layout.preferredHeight: 8 }
}