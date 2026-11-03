import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import "../theme"

WlSessionLock {
    id: lock

    // Starts unlocked. Trigger via IPC — see IpcHandler below.
    locked: false

    property string wallpaper: Quickshell.env("HOME") + "/Pictures/wallpapers/pixel_sakura.gif"
    property string username: Quickshell.env("USER")

    // One of these gets created per connected monitor automatically.
    surface: WlSessionLockSurface {
        id: surfaceRoot

        // ── PAM auth context ────────────────────────────────
        PamContext {
            id: pam

            onCompleted: result => {
                if (result === PamResult.Success) {
                    lock.locked = false;
                } else {
                    passwordField.text = "";
                    errorLabel.text = "incorrect password";
                    errorLabel.visible = true;
                    shakeAnim.start();
                }
            }
        }

        function tryUnlock() {
            errorLabel.visible = false;
            pam.start();
            pam.respond(passwordField.text);
        }

        // ── Background: your animated pixel-sakura gif ──────
        AnimatedImage {
            anchors.fill: parent
            source: lock.wallpaper
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            playing: true
            smooth: false // keep it crisp/pixelated
        }

        // Faint dark overlay so text stays legible over bright sky areas
        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.08
        }

        // ── Top-left: clock + date + battery ────────────────
        ColumnLayout {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 16
            anchors.leftMargin: 56
            spacing: 4

            Text {
                id: clockLabel
                text: Qt.formatTime(clockTimer.now, "hh:mm")
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 52
                font.bold: true
                font.letterSpacing: 2
                color: "#2b2b3a"
            }

            Text {
                text: Qt.formatDate(clockTimer.now, "dddd, MMMM d").toUpperCase()
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 15
                font.letterSpacing: 1
                color: "#e08b8b"
            }

            Text {
                id: batteryLabel
                visible: UPower.displayDevice.isLaptopBattery
                property int pct: Math.round(UPower.displayDevice.percentage * 100)
                property bool charging: UPower.displayDevice.state === UPowerDeviceState.Charging
                text: (charging ? "󱐋" : "") + pct + "%"
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 13
                font.letterSpacing: 1
                color: charging ? "#df8e1d" : (pct <= 15 ? "#c9575e" : "#e08b8b")
            }
        }

        Timer {
            id: clockTimer
            property var now: new Date()
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: now = new Date()
        }

        // ── Center: username / password ─────────────────────
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: lock.username.toUpperCase()
                Layout.alignment: Qt.AlignHCenter
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 22
                font.letterSpacing: 3
                color: "#2b2b3a"
            }

            Text {
                text: "PASSWORD"
                Layout.alignment: Qt.AlignHCenter
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 11
                font.letterSpacing: 2
                color: "#8a8a99"
            }

            Item {
                id: passwordRow
                Layout.alignment: Qt.AlignHCenter
                width: 260
                height: 28

                TextInput {
                    id: passwordField
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    echoMode: TextInput.Password
                    passwordCharacter: "•"
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 18
                    color: "#2b2b3a"
                    focus: true
                    horizontalAlignment: TextInput.AlignHCenter

                    Keys.onReturnPressed: surfaceRoot.tryUnlock()
                    Keys.onEnterPressed: surfaceRoot.tryUnlock()

                    // wobble on wrong password
                    SequentialAnimation on x {
                        id: shakeAnim
                        running: false
                        loops: 1
                        NumberAnimation { to: -8; duration: 40 }
                        NumberAnimation { to: 8; duration: 40 }
                        NumberAnimation { to: -6; duration: 40 }
                        NumberAnimation { to: 6; duration: 40 }
                        NumberAnimation { to: 0; duration: 40 }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: "#c9757e"
                }
            }

            Text {
                id: errorLabel
                Layout.alignment: Qt.AlignHCenter
                visible: false
                text: ""
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 11
                color: "#c9575e"
            }
        }

        // ── Bottom-center: session indicator ─────────────
        RowLayout {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 380
            spacing: 40

            component SessionAction: Text {
                property string label: ""
                signal activated()

                text: "• " + label
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                font.letterSpacing: 1
                color: sessionArea.containsMouse ? "#2b2b3a" : "#8a8a99"

                MouseArea {
                    id: sessionArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.activated()
                }
            }

            SessionAction {
                label: "HYPRLAND"
                onActivated: {}
            }
        }

        Component.onCompleted: passwordField.forceActiveFocus()
    }
}
