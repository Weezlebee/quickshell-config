pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"

ColumnLayout {
    id: root
    spacing: 12
    width: parent ? parent.width : 400

    // --- Data Properties ---
    property string hostname: "..."
    property string distro: "..."
    property string kernel: "..."
    property string device: "..."
    property string firmware: "..."

    property string quickshellVersion: "..."
    property string cliVersion: "..."
    property string shellVersion: "v2.0.3" // Hardcoded example version like in the screenshot

    property string updateStatus: "Click to check"
    property bool checkingUpdate: false

    Component.onCompleted: {
        infoReader.running = true
        versionReader.running = true
        cliVersionReader.running = true
    }

    function checkForUpdates() {
        if (root.checkingUpdate) return;
        root.checkingUpdate = true;
        root.updateStatus = "Checking...";
        updateChecker.running = true;
    }

    // --- System Info Logic ---
    Process {
        id: infoReader
        command: ["hostnamectl"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split('\n');
                for (const line of lines) {
                    const trimmed = line.trim();
                    if (trimmed.startsWith("Static hostname:")) root.hostname = trimmed.split(":")[1].trim();
                    else if (trimmed.startsWith("Operating System:")) root.distro = trimmed.split(":")[1].trim();
                    else if (trimmed.startsWith("Kernel:")) root.kernel = trimmed.split(":")[1].trim();
                    else if (trimmed.startsWith("Hardware Model:")) root.device = trimmed.split(":")[1].trim();
                    else if (trimmed.startsWith("Firmware Version:")) root.firmware = trimmed.split(":")[1].trim();
                }
            }
        }
    }

    // --- Software Version Logic ---
    Process {
        id: versionReader
        command: ["quickshell", "--version"]
        stdout: StdioCollector {
            onStreamFinished: root.quickshellVersion = text.trim().split(" ")[1] ?? "..."
        }
    }

    Process {
        id: cliVersionReader
        command: ["sh", "-c", "caelestia --version 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/caelestia-cli\S*\s+(\d+(?:\.\d+)*)/);
                root.cliVersion = m ? m[1] : "...";
            }
        }
    }

    // --- Update Check Logic ---
    Process {
        id: updateChecker
        command: ["bash", "-c", "cd ~/.config/quickshell && git fetch --quiet 2>&1 && git status -uno"]
        onRunningChanged: {
            if (!running) root.checkingUpdate = false;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.indexOf("Your branch is up to date") !== -1) {
                    root.updateStatus = "Up to date";
                } else if (text.indexOf("behind") !== -1) {
                    const m = text.match(/behind .*? by (\d+) commit/);
                    root.updateStatus = m ? ("Behind by " + m[1] + " commit" + (m[1] === "1" ? "" : "s")) : "Update available";
                } else if (text.indexOf("ahead") !== -1) {
                    root.updateStatus = "Ahead of remote";
                } else {
                    root.updateStatus = "Unknown";
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "") root.updateStatus = "Check failed (not a git repo?)";
            }
        }
    }

    // --- 1. HERO SECTION ---
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 180
        radius: 16
        color: Theme.bg1

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 8

            Image {
                source: "../pictures/Shiba.png"
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                Layout.alignment: Qt.AlignHCenter
                fillMode: Image.PreserveAspectFit
            }

            Text {
                text: "Quickshell"
                color: Theme.text
                font.pixelSize: 22
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }

            // Version Tag Badge (Matches Image 2)
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: tagText.implicitWidth + 20
                implicitHeight: tagText.implicitHeight + 8
                radius: 8
                color: Theme.bg2 // Slightly darker background for the tag

                Text {
                    id: tagText
                    anchors.centerIn: parent
                    text: root.shellVersion
                    color: Theme.subText
                    font.pixelSize: 12
                }
            }
        }
    }

    // --- 2. SYSTEM SECTION ---
    Text {
        text: "System"
        color: Theme.subText
        font.bold: true
        font.pixelSize: 12
        Layout.leftMargin: 8
        Layout.topMargin: 8
    }

    Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: Theme.bg1
        implicitHeight: sysCol.implicitHeight + 24

        ColumnLayout {
            id: sysCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            RowLayout {
                Text { text: "Hostname"; color: Theme.text; Layout.fillWidth: true }
                Text { text: root.hostname; color: Theme.subText }
            }
            RowLayout {
                Text { text: "Device"; color: Theme.text; Layout.fillWidth: true }
                Text { text: root.device; color: Theme.subText }
            }
            RowLayout {
                Text { text: "Distro"; color: Theme.text; Layout.fillWidth: true }
                Text { text: root.distro; color: Theme.subText }
            }
            RowLayout {
                Text { text: "Kernel"; color: Theme.text; Layout.fillWidth: true }
                Text { text: root.kernel; color: Theme.subText }
            }
            RowLayout {
                Text { text: "Firmware"; color: Theme.text; Layout.fillWidth: true }
                Text { text: root.firmware; color: Theme.subText }
            }
        }
    }

    // --- 3.  SECTION ---
    Text {
        text: "Software"
        color: Theme.subText
        font.bold: true
        font.pixelSize: 12
        Layout.leftMargin: 8
        Layout.topMargin: 8
    }

    Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: Theme.bg1
        implicitHeight: softCol.implicitHeight + 24

        ColumnLayout {
            id: softCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            RowLayout {
                Text { text: "Shell"; color: Theme.text; Layout.fillWidth: true }
                Text { text: root.shellVersion; color: Theme.subText }
            }
            RowLayout {
                Text { text: "CLI"; color: Theme.text; Layout.fillWidth: true }
                Text { text: root.cliVersion; color: Theme.subText }
            }
            RowLayout {
                Text { text: "Quickshell"; color: Theme.text; Layout.fillWidth: true }
                Text { text: root.quickshellVersion; color: Theme.subText }
            }
            RowLayout {
                Text { text: "Qt"; color: Theme.text; Layout.fillWidth: true }
                Text { text: Qt.version; color: Theme.subText }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.bg2 }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Updates"; color: Theme.text; Layout.fillWidth: true }
                Text {
                    text: root.checkingUpdate ? "Checking..." : root.updateStatus
                    color: root.checkingUpdate ? Theme.subText : Theme.highlight
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        enabled: !root.checkingUpdate
                        onClicked: root.checkForUpdates()
                    }
                }
            }
        }
    }

    Item { Layout.preferredHeight: 8 }
}