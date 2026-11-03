pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "./"

ColumnLayout {
    id: pluginsPage
    spacing: 14

    FileView {
        id: pluginsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/modules/settings/plugins_settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: pluginsConfig
            property bool weatherWidget: true
            property bool performanceWidget: true
            property bool lyricsWidget: true
            property bool bluetoothQuickToggle: true
        }
    }

    property var pluginList: [
        { key: "weatherWidget", name: "Weather widget", sub: "Show weather in the top bar" },
        { key: "performanceWidget", name: "Performance widget", sub: "CPU/RAM usage indicator" },
        { key: "lyricsWidget", name: "Lyrics", sub: "Show synced lyrics for playing media" },
        { key: "bluetoothQuickToggle", name: "Bluetooth quick toggle", sub: "Quick-access toggle in control center" }
    ]

    Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: Theme.bg1
        implicitHeight: pluginsCol.implicitHeight + 24

        ColumnLayout {
            id: pluginsCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Repeater {
                model: pluginsPage.pluginList

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 56
                    radius: 10
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8

                        ColumnLayout {
                            spacing: 0
                            Layout.fillWidth: true
                            Text { text: modelData.name; color: Theme.text; font.bold: true; font.pixelSize: 13 }
                            Text { text: modelData.sub; color: Theme.subText; font.pixelSize: 10 }
                        }

                        ToggleSwitch {
                            checked: pluginsConfig[modelData.key]
                            onToggled: (v) => pluginsConfig[modelData.key] = v
                        }
                    }
                }
            }
        }
    }

    Item { Layout.preferredHeight: 8 }
}