import "../theme"
import "../top"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool isExpanded: hoverArea.hovered
    property real brightnessVal: 0.7
    property real hyprsunsetVal: 0

    signal requestClose()

    function queueBrightness(val) {
        root.brightnessVal = val;
        brightnessTimer.restart();
    }

    function queueHyprsunset(val) {
        root.hyprsunsetVal = val;
        sunsetTimer.restart();
    }

    function closeWithAnimation() {
        slideInAnimation.restart();
    }

    implicitWidth: 110
    implicitHeight: 274
    width: implicitWidth
    height: implicitHeight
    onVisibleChanged: {
        if (visible)
            slideOutAnimation.restart();

    }
    Component.onCompleted: {
        if (visible)
            slideOutAnimation.restart();

    }

    // ==========================================================
    // DUAL DIRECTIONAL ANIMATION TIMELINES
    // ==========================================================
    ParallelAnimation {
        id: slideOutAnimation

        NumberAnimation {
            target: contentTranslation
            property: "x"
            from: root.width
            to: 0
            duration: 600
            easing.type: Easing.OutCubic
        }

    }

    SequentialAnimation {
        id: slideInAnimation

        ParallelAnimation {
            NumberAnimation {
                target: contentTranslation
                property: "x"
                from: 0
                to: root.width
                duration: 600
                easing.type: Easing.OutCubic
            }

        }

        ScriptAction {
            script: root.requestClose()
        }

    }

    // ==========================================================
    // PROCESSES & TIMERS
    // ==========================================================
    Timer {
        id: sunsetTimer

        interval: 50
        repeat: false
        onTriggered: {
            hyprsunsetProc.running = false;
            if (root.hyprsunsetVal <= 0.01) {
                hyprsunsetProc.command = ["bash", "-c", "hyprctl hyprsunset temperature 6500 || hyprsunset -t 6500"];
            } else {
                var temp = Math.round(6500 - (root.hyprsunsetVal * 4500));
                hyprsunsetProc.command = ["bash", "-c", "hyprctl hyprsunset temperature " + temp + " || hyprsunset -t " + temp];
            }
            hyprsunsetProc.running = true;
        }
    }

    Timer {
        id: brightnessTimer

        interval: 40
        repeat: false
        onTriggered: {
            brightnessProc.running = false;
            var pct = Math.max(1, Math.round(root.brightnessVal * 100));
            brightnessProc.command = ["brightnessctl", "--device=amdgpu_bl1", "s", pct + "%"];
            brightnessProc.running = true;
        }
    }

    Process {
        id: brightnessProc
    }

    Process {
        id: hyprsunsetProc
    }

    // Session control processes
    Process {
        id: lockProc

        command: ["hyprlock"]
    }

    Process {
        id: shutdownProc

        
    }

    Process {
        id: suspendProc

        // Execute via a shell to support the '&&' operator
        command: ["/bin/sh", "-c", "sleep 1 && systemctl suspend"]
    }

    Process {
        id: rebootProc

        
    }

    HoverHandler {
        id: hoverArea
    }

    // ==========================================================
    // ANIMATED CONTENT WRAPPER
    // ==========================================================
    Item {
        id: animatedContent

        anchors.fill: parent

        Item {
            id: bgContainer

            anchors.fill: parent

            // 1. Top Section
            Rectangle {
                id: topSec

                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 12
                width: 60
                height: 38
                color: Theme.bg0
                topLeftRadius: 16
                topRightRadius: 0
                bottomLeftRadius: 0
                bottomRightRadius: 0
            }

            // 2. Middle Section (Expands left)
            Rectangle {
                id: midSec

                anchors.right: parent.right
                anchors.top: topSec.bottom
                width: root.isExpanded ? 110 : 60
                height: 174
                color: Theme.bg0
                topLeftRadius: root.isExpanded ? 16 : 0
                bottomLeftRadius: root.isExpanded ? 16 : 0
                topRightRadius: 0
                bottomRightRadius: 0

                Behavior on width {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on topLeftRadius {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on bottomLeftRadius {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }

                }

            }

            // 3. Bottom Section
            Rectangle {
                id: botSec

                anchors.right: parent.right
                anchors.top: midSec.bottom
                width: 60
                height: 38
                color: Theme.bg0
                bottomLeftRadius: 16
                bottomRightRadius: 0
                topLeftRadius: 0
                topRightRadius: 0
            }

            // Right Bar Fillets
            RoundedCorner {
                anchors.bottom: topSec.top
                anchors.right: topSec.right
                color: Theme.bg0
                size: 16
                corner: 1
                z: 10
            }

            RoundedCorner {
                anchors.top: botSec.bottom
                anchors.right: botSec.right
                color: Theme.bg0
                size: 16
                corner: 2
                z: 10
            }

            // Secondary Panel Fillets
            RoundedCorner {
                anchors.right: topSec.left
                anchors.bottom: topSec.bottom
                color: Theme.bg0
                size: 16
                corner: 1
                z: 10
                visible: root.isExpanded && midSec.width > 65
                opacity: root.isExpanded ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }

                }

            }

            RoundedCorner {
                anchors.right: botSec.left
                anchors.top: botSec.top
                color: Theme.bg0
                size: 16
                corner: 2
                z: 10
                visible: root.isExpanded && midSec.width > 65
                opacity: root.isExpanded ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }

                }

            }

        }

        Item {
            anchors.fill: parent

            Item {
                id: drawerContainer

                x: midSec.x
                y: midSec.y
                width: 50
                height: midSec.height
                z: 20
                opacity: root.isExpanded ? 1 : 0
                visible: opacity > 0

                Rectangle {
                    id: topDot

                    width: 14
                    height: 6
                    radius: 3
                    color: topDotArea.containsMouse ? Theme.rose : Theme.bg3
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 10

                    MouseArea {
                        id: topDotArea

                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointerCursor
                        onClicked: {
                            root.queueBrightness(0.7);
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }

                    }

                }

                Column {
                    id: sliderColumn

                    property int trackHeight: 60

                    width: 26
                    spacing: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 22

                    Rectangle {
                        id: brightnessTrack

                        width: parent.width
                        height: sliderColumn.trackHeight
                        color: Theme.bg1
                        radius: 12
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: parent.height * root.brightnessVal
                            color: Theme.rose
                            radius: 12
                        }

                        Text {
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.topMargin: 4
                            text: "☀️"
                            font.pixelSize: 10
                            z: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            onPositionChanged: (mouse) => {
                                var val = Math.max(0, Math.min(1, 1 - (mouse.y / height)));
                                root.queueBrightness(val);
                            }
                            onClicked: (mouse) => {
                                var val = Math.max(0, Math.min(1, 1 - (mouse.y / height)));
                                root.queueBrightness(val);
                            }
                        }

                    }

                    Rectangle {
                        id: hyprsunsetTrack

                        width: parent.width
                        height: sliderColumn.trackHeight
                        color: Theme.bg1
                        radius: 12
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: parent.height * root.hyprsunsetVal
                            color: Theme.rose
                            radius: 12
                        }

                        Text {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: 4
                            text: "🌙"
                            font.pixelSize: 10
                            z: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            onPositionChanged: (mouse) => {
                                var val = Math.max(0, Math.min(1, 1 - (mouse.y / height)));
                                root.queueHyprsunset(val);
                            }
                            onClicked: (mouse) => {
                                var val = Math.max(0, Math.min(1, 1 - (mouse.y / height)));
                                root.queueHyprsunset(val);
                            }
                        }

                    }

                }

                Rectangle {
                    id: bottomDot

                    width: 14
                    height: 6
                    radius: 3
                    color: bottomDotArea.containsMouse ? Theme.rose : Theme.bg3
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 158

                    MouseArea {
                        id: bottomDotArea

                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointerCursor
                        onClicked: {
                            root.queueHyprsunset(0.3888);
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }

                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                    }

                }

            }

            // ==========================================================
            // ACTION BUTTONS COLUMN
            // ==========================================================
            Column {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.verticalCenter: parent.verticalCenter
                anchors.topMargin: 22
                anchors.rightMargin: 7
                anchors.bottomMargin: 0
                spacing: 20
                z: 20

                // 1. Lock Screen Button
                Rectangle {
                    width: 42
                    height: 42
                    color: lockArea.containsMouse ? Theme.gold : Theme.text
                    radius: 10

                    Text {
                        anchors.centerIn: parent
                        color: Theme.bg2
                        text: ""
                        font.pixelSize: 24
                    }

                    MouseArea {
                        id: lockArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointerCursor
                        onClicked: {
                            root.closeWithAnimation();
                            lockProc.running = true;
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }

                    }

                }

                // 2. Shutdown Button
                Rectangle {
                    width: 42
                    height: 42
                    color: shutdownArea.containsMouse ? Theme.rose : Theme.text
                    radius: 10

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: Theme.bg2
                        font.pixelSize: 24
                    }

                    MouseArea {
                        id: shutdownArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointerCursor
                        onClicked: {
                            root.closeWithAnimation();
                            shutdownProc.running = true;
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }

                    }

                }

                // 3. Suspend Button
                Rectangle {
                    width: 42
                    height: 42
                    color: suspendArea.containsMouse ? Theme.iris : Theme.text
                    radius: 10

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: Theme.bg2
                        font.pixelSize: 28
                    }

                    MouseArea {
                        id: suspendArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointerCursor
                        onClicked: {
                            root.closeWithAnimation();
                            suspendProc.running = true;
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }

                    }

                }

                // 4. Restart Button
                Rectangle {
                    width: 42
                    height: 42
                    color: rebootArea.containsMouse ? Theme.foam : Theme.text
                    radius: 10

                    Text {
                        anchors.centerIn: parent
                        text: "󰜉"
                        color: Theme.bg2
                        font.pixelSize: 32
                    }

                    MouseArea {
                        id: rebootArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointerCursor
                        onClicked: {
                            root.closeWithAnimation();
                            rebootProc.running = true;
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
                        }

                    }

                }

            }

        }

        transform: Translate {
            id: contentTranslation

            x: root.width
        }

    }

}
