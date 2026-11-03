import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import "../theme"

RowLayout {
    spacing: 3

    Repeater {
        model: 5

        Rectangle {
            id: wsButton
            required property int index

            property var ws: Hyprland.workspaces.values.find(w => w.id === index + 1)
            property bool isActive: Hyprland.focusedWorkspace?.id == (index + 1)

            implicitWidth: isActive ? label.implicitWidth + 20 : label.implicitWidth + 12
            implicitHeight: 17
            radius: isActive ? 50 : 25

            color: isActive ? Theme.iris : Theme.bg1

            Behavior on color {
                ColorAnimation { duration: 150 }
            }

            Text {
                id: label
                anchors.centerIn: parent
                text: wsButton.index + 1
                color: wsButton.isActive ? Theme.bg0 : (wsButton.ws ? Theme.text : Theme.grey0)

                font {
                    family: "Rubik"
                    pixelSize: 12
                    weight: 500
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: Hyprland.dispatch("workspace " + (parent.index + 1))
            }
        }
    }
}