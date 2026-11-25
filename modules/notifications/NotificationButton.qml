import QtQuick
import "../theme"

//   left click  -> toggle the notification center
//   right click -> toggle do-not-disturb
Item {
    id: root

    readonly property int count: Notifs.list.length

    implicitWidth: row.implicitWidth + 10
    implicitHeight: Theme.topBarHeight

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            font.family: "Rubik"
            anchors.verticalCenter: parent.verticalCenter
            // nf-md bell-off / bell / bell-outline
            text: Notifs.dnd ? String.fromCodePoint(0xF009B)
                : root.count > 0 ? String.fromCodePoint(0xF009A)
                : String.fromCodePoint(0xF009C)
            color: Notifs.centerOpen || area.containsMouse ? Theme.iris
                : Notifs.dnd ? Theme.subText : Theme.text
            font.pixelSize: 14

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Text {
            font.family: "Rubik"
            anchors.verticalCenter: parent.verticalCenter
            visible: root.count > 0
            text: root.count
            color: Theme.iris
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Notifs.dnd = !Notifs.dnd;
            else
                Notifs.centerOpen = !Notifs.centerOpen;
        }
    }
}
