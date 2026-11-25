import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../theme"

// Now-playing tile for the notification center (any MPRIS player: Spotify,
// Firefox, mpv...). Shows "Nothing playing" when no player is open.
Rectangle {
    id: root

    readonly property var players: {
        const out = [];
        const vals = Mpris.players.values;
        for (let i = 0; i < (vals?.length ?? 0); i++)
            out.push(vals[i]);
        return out;
    }
    // prefer whatever is playing, then Spotify, then the first player
    readonly property var player: players.find(p => p.isPlaying)
        ?? players.find(p => ((p.identity ?? "") + (p.desktopEntry ?? "")).toLowerCase().includes("spotify"))
        ?? players[0] ?? null
    implicitHeight: 76
    radius: 14
    color: Theme.bg1

    // MPRIS doesn't push position updates, so poll while playing
    Timer {
        interval: 1000
        repeat: true
        running: root.player?.isPlaying ?? false
        onTriggered: root.player.positionChanged()
    }

    RowLayout {
        anchors {
            fill: parent
            margins: 10
        }
        spacing: 10

        // album art
        ClippingRectangle {
            implicitWidth: 56
            implicitHeight: 56
            radius: 10
            color: Theme.bg3

            Image {
                id: art
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(112, 112)
                asynchronous: true
            }

            Text {
                font.family: "Rubik"
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: String.fromCodePoint(0xF075A)   // music note
                color: Theme.rose
                font.pixelSize: 22
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                font.family: "Rubik"
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Nothing playing"
                color: Theme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                font.family: "Rubik"
                Layout.fillWidth: true
                text: root.player?.trackArtist || root.player?.identity || ""
                color: Theme.subText
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            // progress
            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 5
                implicitHeight: 3
                radius: 2
                color: Theme.bg3
                visible: (root.player?.lengthSupported ?? false) && root.player.length > 0

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    color: Theme.rose
                    width: root.player && root.player.length > 0
                        ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                }
            }
        }

        RowLayout {
            spacing: 2

            MediaButton {
                glyph: 0xF04AE   // previous
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }
            MediaButton {
                glyph: root.player?.isPlaying ? 0xF03E4 : 0xF040A   // pause / play
                size: 20
                enabled: root.player?.canTogglePlaying ?? false
                onClicked: root.player.togglePlaying()
            }
            MediaButton {
                glyph: 0xF04AD   // next
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }
        }
    }

    component MediaButton: Rectangle {
        id: btn

        property int glyph
        property int size: 16
        signal clicked

        implicitWidth: 26
        implicitHeight: 26
        radius: 13
        color: area.containsMouse ? Theme.bg3 : "transparent"
        opacity: enabled ? 1 : 0.35

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            font.family: "Rubik"
            anchors.centerIn: parent
            text: String.fromCodePoint(btn.glyph)
            color: area.containsMouse ? Theme.rose : Theme.text
            font.pixelSize: btn.size
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
