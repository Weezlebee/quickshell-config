pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../theme"

// Transparent overlay on the right edge of the focused monitor.
// Only the area covered by cards accepts input; everything else clicks through.
PanelWindow {
    id: root

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

    anchors {
        top: true
        right: true
        bottom: true
    }
    margins {
        top: Theme.topBarHeight + Theme.borderWidth + Theme.margin
        right: Theme.borderWidth + Theme.margin
    }

    implicitWidth: 240
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"

    mask: Region {
        item: list
    }

    ListView {
        id: list

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: contentHeight
        spacing: Theme.margin
        interactive: false

        model: ScriptModel {
            values: Notifs.centerOpen ? [] : Notifs.popups.slice(0, Notifs.maxPopups)
        }

        delegate: NotificationCard {
            width: list.width
        }

        add: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    from: list.width
                    to: 0
                    duration: 380
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.8
                }
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 250
                }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "x"
                    to: list.width
                    duration: 260
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "opacity"
                    to: 0
                    duration: 220
                }
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 320
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "opacity"
                to: 1
                duration: 200
            }
        }
    }
}
