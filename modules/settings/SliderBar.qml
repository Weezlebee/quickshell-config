import QtQuick
import "../theme"

Item {
    id: sliderRoot

    property real value: 0.5 // 0..1
    signal moved(real value)

    height: 10

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Theme.bg2

        Rectangle {
            width: parent.width * sliderRoot.value
            height: parent.height
            radius: parent.radius
            color: Theme.rose
        }
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true

        function update(mx) {
            let pct = Math.max(0, Math.min(1, mx / width));
            sliderRoot.value = pct;
            sliderRoot.moved(pct);
        }

        onPressed: (mouse) => update(mouse.x)
        onPositionChanged: (mouse) => update(mouse.x)
    }
}