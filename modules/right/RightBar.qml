import QtQuick
import Quickshell
import Quickshell.Wayland
import "../controlcenter"
import "../theme"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: rightBarWindow
        required property var modelData
        screen: modelData

        implicitWidth: 8
        color: "transparent"
        exclusionMode: ExclusionMode.Auto

        anchors {
            right: true
            bottom: true
            top: true
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.bg0

            Item {
                id: triggerArea
                width: parent.width
                height: 120
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointerCursor
                    onClicked: {
                        if (quickControlsPopup.visible) {
                            quickControlsWidget.closeWithAnimation();
                        } else {
                            quickControlsPopup.visible = true;
                        }
                    }
                }

                PopupWindow {
                    id: quickControlsPopup

                    anchor.window: rightBarWindow
                    implicitWidth: 110
                    implicitHeight: 280

                    // Exact 110px offset matching QuickControls implicitWidth
                    anchor.rect.x: rightBarWindow.width + 735.5
                    anchor.rect.y: (rightBarWindow.height - implicitHeight) / 2
                    anchor.rect.width: 110
                    anchor.rect.height: implicitHeight

                    anchor.edges: Edges.Right
                    anchor.gravity: Edges.Left

                    color: "transparent"
                    visible: false

                    QuickControls {
                        id: quickControlsWidget
                        anchors.fill: parent

                        onRequestClose: {
                            quickControlsPopup.visible = false;
                        }
                    }
                }
            }
        }
    }
}