pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Hyprland
import "../theme"
import "../globalstate"

Item {
    id: barRoot

    FileView {
        id: pluginsFile

        path: Quickshell.env("HOME") + "/.config/quickshell/modules/settings/plugins_settings.json"
        watchChanges: true
        onFileChanged: reload()

        adapter: JsonAdapter {
            id: pluginsConfig

            property bool bottomAppBar: true
        }
    }

    property bool dockEnabled: pluginsConfig.bottomAppBar
    property bool isVisible: dockBackground.anchors.bottomMargin > -78

    property var highlightedApps: [
        "LibreWolf",
        "Spotify",
        "PrusaSlicer",
        "IntelliJ IDEA Community Edition",
        "GPU Screen Recorder",
        "Google Chrome",
        "Files",
        "Zoom Workplace",
        "Settings"
    ]

    property var resolvedApps: {
        let list = [];
        const allApps = DesktopEntries.applications.values;
        for (let i = 0; i < highlightedApps.length; i++) {
            let target = highlightedApps[i];
            if (target === "Settings") {
                list.push({
                    name: "Settings",
                    icon: "preferences-system",
                    isInternalSettings: true,
                    desktopEntry: null
                });
                continue;
            }

            let entry = allApps.find(app =>
                app.name.toLowerCase() === target.toLowerCase() ||
                app.id.toLowerCase().includes(target.toLowerCase())
            );

            if (entry) {
                list.push({
                    name: entry.name,
                    icon: entry.icon,
                    isInternalSettings: false,
                    desktopEntry: entry
                });
            }
        }
        return list;
    }

    implicitWidth: dockBackground.width
    implicitHeight: 54
    clip: false

    Rectangle {
        id: dockBackground

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: barRoot.dockEnabled ? 0 : -80
        width: appRow.implicitWidth + 16
        height: 48
        radius: 14
        color: Theme.bg0
        border.width: 1
        border.color: Theme.bg1

        Behavior on anchors.bottomMargin {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: appRow

            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: barRoot.resolvedApps

                delegate: Item {
                    id: appDelegate

                    required property var modelData

                    property bool isRunning: {
                        if (modelData.isInternalSettings)
                            return GlobalStates.settingsOpen;

                        const toplevels = Hyprland.toplevels.values;
                        const appName = modelData.name.toLowerCase();
                        const appId = (modelData.desktopEntry?.id ?? "").toLowerCase();

                        for (let i = 0; i < toplevels.length; i++) {
                            const t = toplevels[i];
                            const cls = (t.wayland?.appId ?? "").toLowerCase();
                            const title = (t.title ?? "").toLowerCase();
                            if ((cls && (cls.includes(appName) || (appId && appId.includes(cls)))) || title.includes(appName)) {
                                return true;
                            }
                        }
                        return false;
                    }

                    width: 38
                    height: 40
                    scale: mouseArea.containsMouse ? 1.22 : 1.0
                    y: mouseArea.containsMouse ? -6 : 0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutBack
                        }
                    }

                    Behavior on y {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutCubic
                        }
                    }

                    IconImage {
                        id: appIcon

                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        width: 32
                        height: 32
                        visible: !appDelegate.modelData.isInternalSettings
                        source: appDelegate.modelData.isInternalSettings
                            ? ""
                            : Quickshell.iconPath(appDelegate.modelData.icon, true)
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        width: 32
                        height: 32
                        visible: appDelegate.modelData.isInternalSettings
                        text: "⚙"
                        color: Theme.text
                        font.pixelSize: 24
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: 4
                        height: 4
                        radius: 2
                        color: Theme.text
                        visible: appDelegate.isRunning
                    }

                    MouseArea {
                        id: mouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (appDelegate.modelData.isInternalSettings) {
                                GlobalStates.settingsOpen = !GlobalStates.settingsOpen;
                                return;
                            }

                            if (appDelegate.modelData.desktopEntry) {
                                appDelegate.modelData.desktopEntry.execute();
                            }
                        }
                    }
                }
            }
        }
    }
}