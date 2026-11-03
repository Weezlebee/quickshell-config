pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import "../theme"
import "../globalstate"
import "./"

Item {
    id: settingsRoot

    signal requestClose()

    property string currentPage: "wallpaper"

    property var pageTitles: ({
        wallpaper: "Wallpaper & style",
        network: "Network",
        devices: "Connected devices",
        audio: "Audio",
        updates: "Updates",
        plugins: "Plugins",
        services: "Services",
        language: "Language & region",
        about: "About"
    })

    Rectangle {
        id: cardBackground
        anchors.fill: parent
        color: Theme.bg0
        radius: 20
        antialiasing: true
        clip: true
        border.color: Theme.bg0
        border.width: 2

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // --- Sidebar ---
            Rectangle {
                Layout.preferredWidth: 240
                Layout.fillHeight: true
                color: Theme.bg0
                antialiasing: true

                // Round only the left side to match the card's outer radius
                topLeftRadius: cardBackground.radius
                bottomLeftRadius: cardBackground.radius

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    // Fixed search bar (not part of the scroll area)
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 10
                        antialiasing: true
                        color: Theme.bg1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            spacing: 8
                            TextField {
                                Layout.fillWidth: true
                                placeholderText: "Search settings"
                                background: Rectangle { color: "transparent" }
                                color: Theme.text
                                font.pixelSize: 12
                            }
                        }
                    }

                    // Scrollable list of sidebar entries
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                        ColumnLayout {
                            width: parent.width
                            spacing: 4

                            Repeater {
                                model: [
                                    { name: "Wallpaper & style", sub: "Wallpaper, fonts, colours", page: "wallpaper" },
                                    { name: "Network", sub: "Wi-Fi, ethernet", page: "network" },
                                    { name: "Connected devices", sub: "Bluetooth, pairing", page: "devices" },
                                    { name: "Audio", sub: "App volumes, sound devices", page: "audio" },
                                    { name: "Updates", sub: "System updates", page: "updates" },
                                    { name: "Plugins", sub: "Manage plugins", page: "plugins" },
                                    { name: "Services", sub: "Poll intervals, lyrics backend", page: "services" },
                                    { name: "Language & region", sub: "UI language, weather location, display units", page: "language" },
                                    { name: "About", sub: "System information, credits", page: "about" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    height: 48
                                    radius: 12
                                    antialiasing: true
                                    color: settingsRoot.currentPage === modelData.page ? Theme.highlight : "transparent"
                                    opacity: settingsRoot.currentPage === modelData.page ? 0.18 : 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 0

                                        Text {
                                            text: modelData.name
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.bold: true
                                        }
                                        Text {
                                            text: modelData.sub
                                            color: Theme.subText
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: settingsRoot.currentPage = modelData.page
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --- Content pane ---
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 20
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: settingsRoot.pageTitles[settingsRoot.currentPage] || ""
                        color: Theme.text
                        font.pixelSize: 20
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 30; height: 30
                        radius: 8
                        antialiasing: true
                        color: closeMouseArea.containsMouse ? Theme.hover : Theme.bg1

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: Theme.text
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: closeMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: settingsRoot.requestClose()
                        }
                    }
                }

                Flickable {
                    id: pageFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    contentWidth: width
                    contentHeight: pageLoader.item ? pageLoader.item.implicitHeight : height

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    Loader {
                        id: pageLoader
                        width: pageFlick.width
                        sourceComponent: {
                            if (settingsRoot.currentPage === "audio") return audioPageComponent;
                            if (settingsRoot.currentPage === "about") return aboutPageComponent;
                            if (settingsRoot.currentPage === "network") return networkPageComponent;
                            if (settingsRoot.currentPage === "devices") return bluetoothPageComponent;
                            if (settingsRoot.currentPage === "language") return languagePageComponent;
                            if (settingsRoot.currentPage === "wallpaper") return wallpaperPageComponent;
                            if (settingsRoot.currentPage === "updates") return updatesPageComponent;
                            if (settingsRoot.currentPage === "plugins") return pluginsPageComponent;
                            if (settingsRoot.currentPage === "services") return servicesPageComponent;
                            return placeholderComponent;
                        }
                    }
                }

                Component {
                    id: audioPageComponent
                    AudioPage {}
                }

                Component {
                    id: aboutPageComponent
                    AboutPage {}
                }

                Component {
                    id: placeholderComponent
                    Rectangle {
                        radius: 12
                        antialiasing: true
                        color: Theme.bg1
                        border.color: Theme.bg0
                        border.width: 2

                        Text {
                            anchors.centerIn: parent
                            text: settingsRoot.currentPage + " page content goes here"
                            color: Theme.subText
                        }
                    }
                }

                Component {
                    id: networkPageComponent
                    NetworkPage {}
                }

                Component {
                    id: bluetoothPageComponent
                    BluetoothPage {}
                }

                Component {
                    id: languagePageComponent
                    LanguagePage {}
                }

                Component { 
                    id: wallpaperPageComponent
                    WallpaperPage {} 
                }

                Component { 
                    id: updatesPageComponent
                    UpdatesPage {} 
                }

                Component {
                     id: pluginsPageComponent
                    PluginsPage {} 
                    }

                Component { 
                    id: servicesPageComponent
                    ServicesPage {} 
                }
            }
        }
    }

    Keys.onEscapePressed: settingsRoot.requestClose()
}