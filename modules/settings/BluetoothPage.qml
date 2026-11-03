pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"
import "./"

ColumnLayout {
    id: bluetoothPage
    spacing: 14

    property bool powered: true
    property bool discoverable: false
    property bool pairable: false
    property var devices: []

    function refresh() {
        deviceReader.running = true;
    }

    function setPowered(v) {
        let cmd = Qt.createQmlObject('import Quickshell.Io; Process {}', bluetoothPage);
        cmd.command = ["bluetoothctl", "power", v ? "on" : "off"];
        cmd.running = true;
    }

    function setDiscoverable(v) {
        let cmd = Qt.createQmlObject('import Quickshell.Io; Process {}', bluetoothPage);
        cmd.command = ["bluetoothctl", "discoverable", v ? "on" : "off"];
        cmd.running = true;
    }

    function setPairable(v) {
        let cmd = Qt.createQmlObject('import Quickshell.Io; Process {}', bluetoothPage);
        cmd.command = ["bluetoothctl", "pairable", v ? "on" : "off"];
        cmd.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: deviceReader
        command: ["bash", "-c", "bluetoothctl devices"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split('\n').filter(l => l.startsWith("Device"));
                const list = [];
                for (const line of lines) {
                    const parts = line.split(' ');
                    const mac = parts[1];
                    const name = parts.slice(2).join(' ');
                    list.push({ name: name, mac: mac });
                }
                bluetoothPage.devices = list;
            }
        }
    }

    // --- Adapter status ---
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 160
        radius: 12
        color: Theme.bg1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 4

            Text { text: "Adapter status"; color: Theme.text; font.bold: true; font.pixelSize: 14 }
            Text { text: "General adapter settings"; color: Theme.subText; font.pixelSize: 11 }

            Item { height: 6 }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Powered"; color: Theme.text; Layout.fillWidth: true }
                ToggleSwitch {
                    checked: bluetoothPage.powered
                    onToggled: (v) => { bluetoothPage.powered = v; bluetoothPage.setPowered(v); }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Discoverable"; color: Theme.text; Layout.fillWidth: true }
                ToggleSwitch {
                    checked: bluetoothPage.discoverable
                    onToggled: (v) => { bluetoothPage.discoverable = v; bluetoothPage.setDiscoverable(v); }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Pairable"; color: Theme.text; Layout.fillWidth: true }
                ToggleSwitch {
                    checked: bluetoothPage.pairable
                    onToggled: (v) => { bluetoothPage.pairable = v; bluetoothPage.setPairable(v); }
                }
            }
        }
    }

    // --- Devices ---
    Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: Theme.bg1
        implicitHeight: btListCol.implicitHeight + 32

        ColumnLayout {
            id: btListCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Devices (" + bluetoothPage.devices.length + ")"; color: Theme.text; font.bold: true; font.pixelSize: 14; Layout.fillWidth: true }
                Text {
                    text: "refresh"
                    color: Theme.highlight
                    font.pixelSize: 12
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bluetoothPage.refresh()
                    }
                }
            }

            Text {
                visible: bluetoothPage.devices.length === 0
                text: "No devices found"
                color: Theme.subText
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 20
                Layout.bottomMargin: 20
            }

            ListView {
                Layout.fillWidth: true
                implicitHeight: contentHeight
                interactive: false
                clip: true
                spacing: 4
                model: bluetoothPage.devices

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 44
                    radius: 8
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12

                        Text {
                            text: modelData.name
                            color: Theme.text
                            Layout.fillWidth: true
                        }

                        MouseArea {
                            width: 60; height: 26
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let cmd = Qt.createQmlObject('import Quickshell.Io; Process {}', bluetoothPage);
                                cmd.command = ["bluetoothctl", "connect", modelData.mac];
                                cmd.running = true;
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: Theme.bg2
                                Text { anchors.centerIn: parent; text: "connect"; color: Theme.highlight; font.pixelSize: 11 }
                            }
                        }
                    }
                }
            }
        }
    }

    Item { Layout.preferredHeight: 8 }
}