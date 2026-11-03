import "../bluetooth"
import "../controlcenter"
import "../player"
import "../theme"
import "../weather"
import "../widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    PanelWindow {
        // ==========================================================
        // POPUP WINDOWS
        // ==========================================================

        id: topBarWindow

        required property var modelData

        screen: modelData
        implicitHeight: Theme.topBarHeight + 12
        color: "transparent"
        exclusionMode: ExclusionMode.Auto

        // Layer-shell surfaces (this bar, and popups anchored to it) accept
        // no keyboard input by default - fine for a bar, but it also blocks
        // typing in any TextField inside leftMenuPopup/centerMenu. Grant
        // keyboard focus only while one of them is actually open, and give
        // it back the rest of the time so normal desktop use isn't affected.
        WlrLayershell.keyboardFocus: (leftMenuPopup.visible || centerMenu.visible) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            left: true
            right: true
        }

        // ==========================================================
        // BAR BACKGROUND
        // ==========================================================
        Rectangle {
            id: barBackground

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.topBarHeight
            color: Theme.bg0

            // 1. Left Section (Weather & Media Player Trigger)
            RowLayout {
                id: leftStatusSection

                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                WeatherWidget {
                }

                PlayerWidget {
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointerCursor
                    onClicked: {
                        if (!leftMenuPopup.visible) {
                            leftMenuPopup.visible = true;
                            leftMenuContent.animateOpen = true;
                        } else {
                            leftMenuContent.requestClose();
                        }
                    }
                }

            }

            // 2. Middle Section (Workspaces)
            RowLayout {
                anchors.centerIn: parent

                Workspaces {
                }

            }

            // 3. Right Section (Status Widgets)
            RowLayout {
                id: rightStatusSection

                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Clock {
                }

                BluetoothWidget {
                }

                Volume {
                }

                Network {
                }

                Battery {
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointerCursor
                    onClicked: {
                        if (!centerMenu.visible) {
                            centerMenu.visible = true;
                            controlCenterContent.animateOpen = true;
                        } else {
                            controlCenterContent.requestClose();
                        }
                    }
                }

            }

        }

        // ==========================================================
        // CONCAVE FILLETS (Bar to Desktop Outer Bottom Corners)
        // ==========================================================
        RoundedCorner {
            id: bottomLeftFillet

            anchors.top: barBackground.bottom
            anchors.left: barBackground.left
            color: Theme.bg0
            size: 12
            corner: 3
        }

        RoundedCorner {
            id: bottomRightFillet

            anchors.top: barBackground.bottom
            anchors.right: barBackground.right
            color: Theme.bg0
            size: 12
            corner: 2
        }

        // ==========================================================
        // CONCAVE FILLETS (Dashboard Popup Connectors)
        // ==========================================================
        RoundedCorner {
            id: popupLeftFillet

            visible: leftMenuPopup.visible
            color: Theme.bg0
            size: 12
            corner: 2
            anchors.top: barBackground.bottom
            x: Math.round((modelData.width - leftMenuPopup.implicitWidth) / 2 + 1100) - size
        }

        RoundedCorner {
            id: popupRightFillet

            visible: leftMenuPopup.visible
            color: Theme.bg0
            size: 12
            corner: 3
            anchors.top: barBackground.bottom
            x: Math.round((modelData.width + leftMenuPopup.implicitWidth) / 2 + 1100)
        }

        // Dashboard Popup
        PopupWindow {
            // FIXED MAX WIDTH/HEIGHT to eliminate Wayland surface resize stutter.
            // LeftMenu itself is NOT anchors.fill'd to this window (see below) -
            // it's top/left/right-anchored only, so its own internal height
            // (which animates between the Weather and Player tabs) is free to
            // be smaller than this fixed surface, leaving transparent space
            // below it instead of resizing the actual Wayland surface.

            id: leftMenuPopup

            property int weatherPanelX: (modelData.width - implicitWidth) / 2 + 1100
            property int playerPanelX: (modelData.width - implicitWidth) / 2 + 1200
            property int schedulePanelX: (modelData.width - implicitWidth) / 2 + 1230
            property int homeworkPanelX: (modelData.width - implicitWidth) / 2 + 1125
            anchor.window: topBarWindow
            implicitWidth: 550
            implicitHeight: 300
            anchor.rect.x: {
                if (leftMenuContent.currentTabIndex === 0)
                    return weatherPanelX;

                if (leftMenuContent.currentTabIndex === 1)
                    return playerPanelX;

                if (leftMenuContent.currentTabIndex === 2)
                    return schedulePanelX;

                return homeworkPanelX;
            }
            anchor.rect.width: 1
            anchor.rect.height: topBarWindow.height
            anchor.edges: Edges.Top
            anchor.gravity: Edges.Bottom
            anchor.margins.top: 25
            color: "transparent"
            visible: false

            LeftMenu {
                id: leftMenuContent

                x: (parent.width - width) / 2
                anchors.top: parent.top
                anchors.left: parent.left
                onClosed: leftMenuPopup.visible = false
            }

        }

        // Right Side Control Center Popup
        PopupWindow {
            id: centerMenu

            anchor.window: topBarWindow
            anchor.edges: Edges.Top | Edges.Left
            anchor.gravity: Edges.Bottom | Edges.Right
            anchor.margins.left: topBarWindow.width + 529.5
            anchor.margins.top: Theme.topBarHeight + 0
            width: 324
            height: 242
            color: "transparent"
            visible: false

            ControlCenter {
                id: controlCenterContent

                anchors.top: parent.top
                anchors.right: parent.right
                onClosed: centerMenu.visible = false
            }

        }

    }

}
