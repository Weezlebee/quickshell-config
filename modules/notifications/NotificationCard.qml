pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import "../theme"

// One notification card, used by both the popups and the notification center.
//   left click  -> run the app's default action (popup: dismiss if there is none)
//   right/middle click or ✕ -> dismiss
//   hover -> pauses the timeout (popups only)
Item {
    id: root

    required property var modelData          // NotifEntry
    property bool inCenter: false            // true when shown inside NotificationCenter
    readonly property Notification n: modelData?.notification ?? null

    readonly property bool critical: n?.urgency === NotificationUrgency.Critical
    readonly property color accent: critical ? Theme.rose
        : n?.urgency === NotificationUrgency.Low ? Theme.foam
        : Theme.iris

    // Same countdown for every app (critical ones stay until dismissed).
    // Set Notifs.respectAppTimeout to true to honour the timeout an app asks for.
    readonly property int timeout: (inCenter || critical) ? 0 : Notifs.timeoutFor(n)

    readonly property var buttons: (n?.actions ?? []).filter(a => a.identifier !== "default")

    readonly property string iconSource: {
        const icon = n?.appIcon ?? "";
        if (icon === "")
            return "";
        if (icon.startsWith("/") || icon.startsWith("file://") || icon.startsWith("image://"))
            return icon;
        return Quickshell.iconPath(icon, true);
    }

    implicitHeight: card.implicitHeight

    // Countdown: a plain timer that ticks while not hovered
    property int remaining: timeout
    readonly property real progress: timeout > 0 ? Math.max(0, remaining / timeout) : 0

    Timer {
        interval: 50
        repeat: true
        running: root.timeout > 0 && !hover.hovered && root.remaining > 0
        onTriggered: {
            root.remaining -= interval;
            if (root.remaining > 0 || !root.modelData)
                return;
            if (root.n?.transient)
                root.modelData.dismiss();      // transient = don't keep in history
            else
                root.modelData.popup = false;  // move to the notification center
        }
    }

    HoverHandler {
        id: hover
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onTapped: (eventPoint, button) => {
            if (!root.modelData)
                return;
            if (button === Qt.LeftButton) {
                if (root.modelData.invokeDefault()) {
                    if (root.inCenter)
                        Notifs.centerOpen = false;
                    return;
                }
                if (root.inCenter)
                    return;  // don't clear history on a stray click
            }
            root.modelData.dismiss();
        }
    }

    Rectangle {
        id: card

        width: parent.width
        implicitHeight: content.implicitHeight + 18
        radius: Theme.radius - 12
        color: root.inCenter ? Theme.bg1 : Theme.bg0
        border.width: root.critical ? 2 : (root.inCenter ? 0 : 1)
        border.color: root.critical ? root.accent : Theme.border

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        scale: hover.hovered && !root.inCenter ? 1.01 : 1
        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: content

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 9
            }
            spacing: 4

            // ── header: icon · app name · time · close ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Item {
                    implicitWidth: 13
                    implicitHeight: 13

                    IconImage {
                        id: appIcon
                        anchors.fill: parent
                        source: root.iconSource
                        visible: root.iconSource !== "" && status === Image.Ready
                    }

                    // fallback: first letter in a colored circle
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: root.accent
                        visible: !appIcon.visible

                        Text {
                            font.family: "Rubik"
                            anchors.centerIn: parent
                            text: (root.n?.appName || "?").charAt(0).toUpperCase()
                            color: Theme.bg0
                            font.pixelSize: 8
                            font.bold: true
                        }
                    }
                }

                Text {
                    font.family: "Rubik"
                    text: root.n?.appName || "Notification"
                    color: Theme.subText
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.maximumWidth: 200
                }

                Text {
                    font.family: "Rubik"
                    text: "· " + (root.inCenter
                        ? Notifs.timeAgo(root.modelData?.time, Notifs.now)
                        : Qt.formatTime(root.modelData?.time ?? new Date(), "h:mm AP"))
                    color: Theme.placeholder
                    font.pixelSize: 10
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: 8
                    color: closeArea.containsMouse ? Theme.bg3 : "transparent"
                    opacity: hover.hovered ? 1 : 0.5

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Text {
                        font.family: "Rubik"
                        anchors.centerIn: parent
                        text: "✕"
                        color: closeArea.containsMouse ? Theme.rose : Theme.subText
                        font.pixelSize: 8
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modelData?.dismiss()
                    }
                }
            }

            // ── body: optional image + summary/body text ──
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ClippingRectangle {
                    visible: (root.n?.image ?? "") !== ""
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 8
                    color: Theme.bg1
                    Layout.alignment: Qt.AlignTop

                    Image {
                        anchors.fill: parent
                        source: root.n?.image ?? ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(104, 104)
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        font.family: "Rubik"
                        Layout.fillWidth: true
                        text: root.n?.summary ?? ""
                        visible: text !== ""
                        color: Theme.text
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.Wrap
                    }

                    Text {
                        font.family: "Rubik"
                        Layout.fillWidth: true
                        text: root.n?.body ?? ""
                        visible: text !== ""
                        color: Theme.subText
                        linkColor: root.accent
                        font.pixelSize: 11
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        maximumLineCount: hover.hovered ? 12 : 4
                        elide: Text.ElideRight
                        lineHeight: 1.1
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
            }

            // ── action buttons ──
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 6
                visible: root.buttons.length > 0

                Repeater {
                    model: root.buttons

                    delegate: Rectangle {
                        id: btn
                        required property var modelData   // NotificationAction

                        Layout.fillWidth: true
                        implicitHeight: 22
                        radius: 7
                        color: btnArea.pressed ? Theme.bg3 : btnArea.containsMouse ? Theme.bg2 : (root.inCenter ? Theme.bg0 : Theme.bg1)

                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            font.family: "Rubik"
                            anchors.centerIn: parent
                            width: parent.width - 16
                            horizontalAlignment: Text.AlignHCenter
                            text: btn.modelData?.text ?? ""
                            color: btnArea.containsMouse ? root.accent : Theme.text
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: btnArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: btn.modelData?.invoke()
                        }
                    }
                }
            }

            // ── timeout bar ──
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 2
                implicitHeight: 2
                radius: 1
                color: Theme.bg1
                visible: root.timeout > 0

                Rectangle {
                    width: parent.width * root.progress
                    height: parent.height
                    Behavior on width { NumberAnimation { duration: 60 } }
                    radius: parent.radius
                    color: root.accent
                    opacity: hover.hovered ? 0.5 : 1
                }
            }
        }
    }
}
