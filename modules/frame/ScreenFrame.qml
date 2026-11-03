import Quickshell
import QtQuick

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData

        screen: modelData

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        color: "transparent"

        exclusionMode: ExclusionMode.Ignore

        Canvas {
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d")

                ctx.clearRect(0, 0, width, height)

                ctx.strokeStyle = "#191724"
                ctx.lineWidth = 10

                var r = 25

                ctx.beginPath()

                // top left
                ctx.moveTo(0, r)
                ctx.arc(r, r, r, Math.PI, Math.PI * 1.5)

                // top right
                ctx.moveTo(width - r, 0)
                ctx.arc(width - r, r, r, Math.PI * 1.5, 0)

                // bottom right
                ctx.moveTo(width, height - r)
                ctx.arc(width - r, height - r, r, 0, Math.PI * 0.5)

                // bottom left
                ctx.moveTo(r, height)
                ctx.arc(r, height - r, r, Math.PI * 0.5, Math.PI)

                ctx.stroke()
            }
        }
    }
}