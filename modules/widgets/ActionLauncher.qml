import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ItemDelegate {
    id: actionDelegate
    required property var modelData
    required property int index

    signal actionTriggered(string action)

    width: ListView.view.width
    height: 52

    background: Rectangle {
        color: actionDelegate.hovered ? "rgba(255, 255, 255, 0.06)" : "transparent"
        radius: 10
    }

    contentItem: RowLayout {
        anchors.fill: parent
        anchors.margins: 6
        spacing: 12

        Rectangle {
            width: 36
            height: 36
            color: "#ebbcba"
            radius: 8

            Text {
                anchors.centerIn: parent
                text: ">"
                color: "#191724"
                font.bold: true
                font.pixelSize: 16
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: actionDelegate.modelData.name || ""
                font.pixelSize: 14
                font.bold: true
                color: "#e0def4"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: actionDelegate.modelData.comment || ""
                font.pixelSize: 11
                color: "#908caa"
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
    }

    onClicked: {
        actionDelegate.actionTriggered(actionDelegate.modelData.action);
    }
}