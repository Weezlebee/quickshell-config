pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../globalstate"

ColumnLayout {
    id: servicesPage
    spacing: 14

    FileView {
        id: servicesFile
        path: Quickshell.env("HOME") + "/.config/quickshell/modules/settings/services_settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: servicesConfig
            property int weatherPollMinutes: 15
            property int batteryPollSeconds: 5
            property string lyricsBackend: "lrclib"
        }
    }

    function stepWeather(delta) {
        servicesConfig.weatherPollMinutes = Math.max(1, servicesConfig.weatherPollMinutes + delta);
    }

    function stepBattery(delta) {
        servicesConfig.batteryPollSeconds = Math.max(1, servicesConfig.batteryPollSeconds + delta);
    }

    // --- Poll intervals ---
    Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: Theme.bg1
        implicitHeight: pollCol.implicitHeight + 24

        ColumnLayout {
            id: pollCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            Text { text: "Poll intervals"; color: Theme.text; font.bold: true; font.pixelSize: 14 }

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Text { text: "Weather (minutes)"; color: Theme.text }
                    Text { text: "How often to refresh weather data"; color: Theme.subText; font.pixelSize: 10 }
                }
                Text { text: servicesConfig.weatherPollMinutes; color: Theme.text; Layout.preferredWidth: 30 }
                Rectangle {
                    width: 26; height: 26; radius: 6; color: Theme.bg2
                    Text { anchors.centerIn: parent; text: "▲"; color: Theme.highlight; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: servicesPage.stepWeather(1) }
                }
                Rectangle {
                    width: 26; height: 26; radius: 6; color: Theme.bg2
                    Text { anchors.centerIn: parent; text: "▼"; color: Theme.highlight; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: servicesPage.stepWeather(-1) }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Text { text: "Battery (seconds)"; color: Theme.text }
                    Text { text: "How often to refresh battery status"; color: Theme.subText; font.pixelSize: 10 }
                }
                Text { text: servicesConfig.batteryPollSeconds; color: Theme.text; Layout.preferredWidth: 30 }
                Rectangle {
                    width: 26; height: 26; radius: 6; color: Theme.bg2
                    Text { anchors.centerIn: parent; text: "▲"; color: Theme.highlight; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: servicesPage.stepBattery(1) }
                }
                Rectangle {
                    width: 26; height: 26; radius: 6; color: Theme.bg2
                    Text { anchors.centerIn: parent; text: "▼"; color: Theme.highlight; font.pixelSize: 10 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: servicesPage.stepBattery(-1) }
                }
            }
        }
    }

    // --- Lyrics backend ---
    Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: Theme.bg1
        implicitHeight: lyricsCol.implicitHeight + 24

        ColumnLayout {
            id: lyricsCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Text { text: "Lyrics backend"; color: Theme.text; font.bold: true; font.pixelSize: 14 }

            RowLayout {
                spacing: 8
                Repeater {
                    model: ["none", "lrclib", "musixmatch"]
                    delegate: Rectangle {
                        required property string modelData
                        implicitWidth: backendText.implicitWidth + 24
                        height: 32
                        radius: 8
                        color: servicesConfig.lyricsBackend === modelData ? Theme.highlight : Theme.bg2
                        opacity: servicesConfig.lyricsBackend === modelData ? 0.25 : 1

                        Text {
                            id: backendText
                            anchors.centerIn: parent
                            text: modelData
                            color: Theme.text
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: servicesConfig.lyricsBackend = modelData
                        }
                    }
                }
            }
        }
    }

    Item { Layout.preferredHeight: 8 }
}