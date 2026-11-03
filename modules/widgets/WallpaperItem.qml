pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "../theme"

ItemDelegate {
    id: root

    required property string filePath
    required property string fileName
    required property string fileUrl
    required property int index

    signal selected(string fileName)

    implicitWidth: 220
    implicitHeight: 125
    width: 220
    height: 125

    background: Rectangle { color: "transparent" }

    contentItem: Item {
        anchors.fill: parent

        // Buffer margin to prevent highlight outline clipping
        Item {
            anchors.fill: parent
            anchors.margins: 4

            // Outer Card (Frame & Highlight Border)
            Rectangle {
                id: card
                anchors.fill: parent
                radius: 12
                color: Theme.bg1
                border.color: root.hovered ? Theme.highlight : "transparent"
                border.width: root.hovered ? 2 : 0

                Behavior on border.color {
                    ColorAnimation { duration: 150 }
                }

                // Inner Content Wrapper (Clips both Image & Label cleanly)
                Item {
                    id: innerContent
                    anchors.fill: parent
                    anchors.margins: card.border.width

                    // Single Masking Layer for the entire inner content
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                        maskSource: ShaderEffectSource {
                            sourceItem: Rectangle {
                                width: innerContent.width
                                height: innerContent.height
                                radius: 10
                                color: "black"
                            }
                        }
                    }

                    // 1. Wallpaper Image
                    Image {
                        anchors.fill: parent
                        source: root.fileUrl !== "" ? root.fileUrl : ("file://" + root.filePath)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    // 2. Bottom Label Overlay
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 28
                        color: Theme.bg0
                        opacity: 0.88

                        Text {
                            anchors.centerIn: parent
                            width: parent.width - 12
                            text: root.fileName
                            color: Theme.text
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideMiddle
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }

    onClicked: {
        root.selected(root.fileName)
    }
}