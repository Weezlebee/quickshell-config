import QtQuick
import "../theme"

Item {
    id: toggle

    property bool checked: false
    signal toggled(bool value)

    width: 44
    height: 24

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: toggle.checked ? Theme.love : Theme.bg2

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    Rectangle {
        id: knob
        width: parent.height - 4
        height: width
        radius: width / 2
        color: Theme.rose
        y: 2
        x: toggle.checked ? parent.width - width - 2 : 2

        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggle.checked = !toggle.checked;
            toggle.toggled(toggle.checked);
        }
    }
}