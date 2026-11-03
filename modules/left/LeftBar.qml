import "../controlcenter"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: leftBarWindow

        required property var modelData

        screen: modelData
        implicitWidth: 8
        color: "transparent"
        exclusionMode: ExclusionMode.Auto

        anchors {
            top: true
            bottom: true
            left: true
        }

        Rectangle {
            id: barBackground

            anchors.fill: parent
            color: Theme.bg0

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointerCursor

                onClicked: {
                    if (perfPopup.visible) {
                        performanceWidget.closeWithAnimation()
                    } else {
                        perfPopup.visible = true
                    }
                }
            }
        }

        PopupWindow {
            id: perfPopup

            anchor.window: leftBarWindow
            implicitWidth: 140
            implicitHeight: 320

            anchor.rect.x: leftBarWindow.width + 853.25
            anchor.rect.y: 0
            anchor.rect.width: 1
            anchor.rect.height: leftBarWindow.height

            anchor.edges: Edges.Left
            anchor.gravity: Edges.Right

            color: "transparent"
            visible: false

            PerformanceWidget {
                id: performanceWidget

                anchors.fill: parent

                onRequestClose: {
                    perfPopup.visible = false
                }
            }
        }
    }
}