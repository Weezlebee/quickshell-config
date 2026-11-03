pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../theme"
import "./"

ColumnLayout {
    id: audioPage
    spacing: 14

    property real outputLevel: 0.5
    property real inputLevel: 1.0
    property bool outputMuted: false
    property bool inputMuted: false

    function setVolume(level) {
        let cmd = Qt.createQmlObject('import Quickshell.Io; Process {}', audioPage);
        cmd.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", Math.round(level * 100) + "%"];
        cmd.running = true;
    }

    function setMic(level) {
        let cmd = Qt.createQmlObject('import Quickshell.Io; Process {}', audioPage);
        cmd.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", Math.round(level * 100) + "%"];
        cmd.running = true;
    }

    function setOutputMute(muted) {
        let cmd = Qt.createQmlObject('import Quickshell.Io; Process {}', audioPage);
        cmd.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", muted ? "1" : "0"];
        cmd.running = true;
    }

    function setInputMute(muted) {
        let cmd = Qt.createQmlObject('import Quickshell.Io; Process {}', audioPage);
        cmd.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", muted ? "1" : "0"];
        cmd.running = true;
    }

    // --- Output ---
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 90
        radius: 12
        color: Theme.bg1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Output"; color: Theme.iris; font.bold: true; font.pixelSize: 14 }
                Item { Layout.fillWidth: true }
                Text { text: Math.round(audioPage.outputLevel * 100) + "%"; color: Theme.iris; font.pixelSize: 13 }
            }

            SliderBar {
                Layout.fillWidth: true
                value: audioPage.outputLevel
                onMoved: (v) => { audioPage.outputLevel = v; audioPage.setVolume(v); }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 44
        radius: 12
        color: Theme.bg1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            Text { text: "Muted"; color: Theme.iris; Layout.fillWidth: true }
            ToggleSwitch {
                checked: audioPage.outputMuted
                onToggled: (v) => { audioPage.outputMuted = v; audioPage.setOutputMute(v); }
            }
        }
    }

    // --- Input ---
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 90
        radius: 12
        color: Theme.bg1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Input"; color: Theme.foam; font.bold: true; font.pixelSize: 14 }
                Item { Layout.fillWidth: true }
                Text { text: Math.round(audioPage.inputLevel * 100) + "%"; color: Theme.foam; font.pixelSize: 13 }
            }

            SliderBar {
                Layout.fillWidth: true
                value: audioPage.inputLevel
                onMoved: (v) => { audioPage.inputLevel = v; audioPage.setMic(v); }
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 44
        radius: 12
        color: Theme.bg1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            Text { text: "Muted"; color: Theme.foam; Layout.fillWidth: true }
            ToggleSwitch {
                checked: audioPage.inputMuted
                onToggled: (v) => { audioPage.inputMuted = v; audioPage.setInputMute(v); }
            }
        }
    }

    Item { Layout.fillHeight: true }
}