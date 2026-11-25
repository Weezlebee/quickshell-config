pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../theme"
import "./center"

// macOS / swaync-style notification center: a full-height panel that slides
// out to the right from the left side bar.
// Toggle with Notifs.centerOpen (NotificationButton does this), or:
//   qs ipc call notifs toggleCenter
// Close with the same toggle (or Esc while the panel has focus).
// Only the panel itself takes input; the rest of the screen works normally.
PanelWindow {
    id: root

    // ── tweakables ──
    readonly property int panelWidth: 320
    readonly property int sideOffset: Theme.borderWidth + Theme.margin                          // gap from the left bar
    readonly property int topOffset: Theme.topBarHeight + Theme.borderWidth + Theme.margin      // gap below the top bar
    readonly property int bottomOffset: Theme.borderWidth + Theme.margin                        // gap above the bottom bar

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

    anchors {
        top: true
        bottom: true
        left: true
    }
    // the window is exactly the panel's size, so nothing else gets blocked
    margins {
        top: topOffset
        bottom: bottomOffset
        left: sideOffset
    }
    implicitWidth: panelWidth
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notification-center"
    WlrLayershell.keyboardFocus: Notifs.centerOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // 0 = hidden, 1 = fully shown; keep the window alive while animating out
    property real reveal: Notifs.centerOpen ? 1 : 0
    Behavior on reveal {
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
    }
    visible: Notifs.centerOpen || reveal > 0.001

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Notifs.centerOpen = false
    }

    Rectangle {
        id: panel

        anchors.fill: parent
        radius: Theme.radius - 8
        color: Theme.bg0
        border.width: 1
        border.color: Theme.border
        clip: true

        // slide out from behind the left bar
        opacity: Math.min(1, root.reveal * 2.5)
        transform: Translate { x: -(1 - root.reveal) * root.panelWidth }

        ColumnLayout {
            id: body

            anchors {
                fill: parent
                margins: 10
            }
            spacing: 8

            // ── control-center tiles ──
            CenterWeather {
                Layout.fillWidth: true
            }

            CenterMedia {
                Layout.fillWidth: true
            }

            // ── header ──
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.leftMargin: 4
                spacing: 6

                Text {
                    font.family: "Rubik"
                    text: "Notifications"
                    color: Theme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    visible: Notifs.list.length > 0
                    implicitWidth: Math.max(18, countText.implicitWidth + 10)
                    implicitHeight: 16
                    radius: 8
                    color: Theme.bg1

                    Text {
                        font.family: "Rubik"
                        id: countText
                        anchors.centerIn: parent
                        text: Notifs.list.length
                        color: Theme.iris
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }

                Item { Layout.fillWidth: true }

                // do-not-disturb toggle
                HeaderButton {
                    label: Notifs.dnd ? String.fromCodePoint(0xF009B) : String.fromCodePoint(0xF009A)
                    active: Notifs.dnd
                    onClicked: Notifs.dnd = !Notifs.dnd
                }

                HeaderButton {
                    label: "Clear"
                    enabled: Notifs.list.length > 0
                    onClicked: Notifs.clearAll()
                }
            }

            // ── list ──
            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: Notifs.list.length > 0
                spacing: 6
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                model: ScriptModel {
                    values: Notifs.list
                }

                delegate: NotificationCard {
                    width: list.width
                    inCenter: true
                }

                add: Transition {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
                }
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "x"; to: -list.width; duration: 220; easing.type: Easing.InCubic }
                        NumberAnimation { property: "opacity"; to: 0; duration: 200 }
                    }
                }
                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: 240; easing.type: Easing.OutCubic }
                    NumberAnimation { property: "opacity"; to: 1; duration: 150 }
                }
            }

            // ── empty state ──
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: Notifs.list.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        font.family: "Rubik"
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: String.fromCodePoint(0xF009C)
                        color: Theme.grey0
                        font.pixelSize: 28
                    }
                    Text {
                        font.family: "Rubik"
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Notifs.dnd ? "Do not disturb is on" : "No notifications"
                        color: Theme.subText
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    component HeaderButton: Rectangle {
        id: btn

        property string label
        property bool active: false
        signal clicked

        implicitWidth: btnText.implicitWidth + 16
        implicitHeight: 22
        radius: 11
        opacity: enabled ? 1 : 0.4
        color: active ? Theme.iris
            : btnArea.containsMouse ? Theme.bg3 : Theme.bg1

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            font.family: "Rubik"
            id: btnText
            anchors.centerIn: parent
            text: btn.label
            color: btn.active ? Theme.bg0 : Theme.text
            font.pixelSize: 11
            font.weight: Font.Medium
        }

        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
