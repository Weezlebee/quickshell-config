pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

ColumnLayout {
    id: updatesPage
    spacing: 14

    property var pendingUpdates: []
    property bool checking: false
    property bool checkupdatesAvailable: true

    function refresh() {
        updatesPage.checking = true;
        checkProcess.running = true;
    }

    Component.onCompleted: refresh()

    Process {
        id: checkProcess
        command: ["bash", "-c", "checkupdates 2>/dev/null || echo '__NO_CHECKUPDATES__'"]
        onRunningChanged: {
            if (!running) updatesPage.checking = false;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                const trimmed = text.trim();
                if (trimmed === "__NO_CHECKUPDATES__" || trimmed === "") {
                    updatesPage.checkupdatesAvailable = trimmed !== "__NO_CHECKUPDATES__";
                    updatesPage.pendingUpdates = [];
                    return;
                }
                updatesPage.checkupdatesAvailable = true;
                const lines = trimmed.split('\n');
                const list = [];
                for (const line of lines) {
                    const parts = line.split(' ');
                    if (parts.length >= 4) {
                        list.push({ pkg: parts[0], oldVer: parts[1], newVer: parts[3] });
                    }
                }
                updatesPage.pendingUpdates = list;
            }
        }
    }

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
                Text { text: "System updates"; color: Theme.text; font.bold: true; font.pixelSize: 14 }
                Text {
                    text: updatesPage.checkupdatesAvailable
                        ? (updatesPage.pendingUpdates.length + " package(s) pending")
                        : "checkupdates not installed (pacman-contrib)"
                    color: Theme.subText
                    font.pixelSize: 11
                }
            }
            Text {
                text: updatesPage.checking ? "checking..." : "refresh"
                color: updatesPage.checking ? Theme.subText : Theme.highlight
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    enabled: !updatesPage.checking
                    onClicked: updatesPage.refresh()
                }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: Theme.bg1
        implicitHeight: updateListCol.implicitHeight + 32
        visible: updatesPage.pendingUpdates.length > 0

        ColumnLayout {
            id: updateListCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Text { text: "Packages"; color: Theme.text; font.bold: true; font.pixelSize: 14 }

            ListView {
                Layout.fillWidth: true
                implicitHeight: contentHeight
                interactive: false
                clip: true
                spacing: 4
                model: updatesPage.pendingUpdates

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 40
                    radius: 8
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        Text { text: modelData.pkg; color: Theme.text; Layout.fillWidth: true }
                        Text { text: modelData.oldVer + " → " + modelData.newVer; color: Theme.subText; font.pixelSize: 11 }
                    }
                }
            }
        }
    }

    Text {
        visible: updatesPage.checkupdatesAvailable && updatesPage.pendingUpdates.length === 0 && !updatesPage.checking
        text: "System is up to date"
        color: Theme.subText
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 20
    }

    Item { Layout.preferredHeight: 8 }
}