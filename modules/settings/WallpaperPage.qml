pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../theme"
import "./"

ColumnLayout {
    id: wallpaperPage
    spacing: 14

    property string activeTheme: themeFileView.text().trim() || "main"
    property bool isDark: modeFileView.text().trim() !== "light"

    FileView {
        id: themeFileView
        path: Quickshell.env("HOME") + "/.config/appearance/theme/which_theme"
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: modeFileView
        path: Quickshell.env("HOME") + "/.config/appearance/theme/mode"
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: appearanceFile
        path: Quickshell.env("HOME") + "/.config/quickshell/modules/settings/appearance_settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            id: appearanceConfig
            property bool displayWallpaper: true
            property real transparencyBase: 0.75
            property real transparencyLayers: 0.4
        }
    }

    FolderListModel {
        id: wallpaperFolderModel
        folder: "file://" + Quickshell.env("HOME") + "/Pictures/wallpapers/" + wallpaperPage.activeTheme
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif"]
        showDirs: false
    }

    function setWallpaper(fileName) {
        if (!fileName) return;
        let basePath = Quickshell.env("HOME") + "/Pictures/wallpapers/" + wallpaperPage.activeTheme + "/";
        let cmd = Qt.createQmlObject('import Quickshell.Io; Process {}', wallpaperPage);
        cmd.command = ["awww", "img", basePath + fileName, "--transition-type", "random"];
        cmd.running = true;
    }

    function setDark(v) {
        modeFileView.setText(v ? "dark" : "light");
    }

    // --- Preview ---
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 200
        radius: 16
        color: Theme.bg1
        clip: true

        Image {
            anchors.fill: parent
            source: wallpaperFolderModel.count > 0 ? wallpaperFolderModel.get(0, "fileUrl") : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }

        Text {
            visible: wallpaperFolderModel.count === 0
            anchors.centerIn: parent
            text: "No wallpapers found for theme: " + wallpaperPage.activeTheme
            color: Theme.subText
        }
    }

    // --- Wallpaper grid ---
    Rectangle {
        Layout.fillWidth: true
        radius: 12
        color: Theme.bg1
        implicitHeight: 200

        GridView {
            anchors.fill: parent
            anchors.margins: 12
            cellWidth: 110
            cellHeight: 70
            interactive: false
            model: wallpaperFolderModel

            delegate: Rectangle {
                required property string fileUrl
                required property string fileName
                width: 100
                height: 60
                radius: 8
                color: Theme.bg2
                clip: true

                Image {
                    anchors.fill: parent
                    source: fileUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wallpaperPage.setWallpaper(fileName)
                }
            }
        }
    }

    // --- Display wallpaper toggle ---
    Rectangle {
        Layout.fillWidth: true
        height: 56
        radius: 12
        color: Theme.bg1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            Text { text: "Display wallpaper"; color: Theme.text; font.bold: true; Layout.fillWidth: true }
            ToggleSwitch {
                checked: appearanceConfig.displayWallpaper
                onToggled: (v) => appearanceConfig.displayWallpaper = v
            }
        }
    }

    // --- Transparency ---
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 140
        radius: 12
        color: Theme.bg1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            Text { text: "Transparency"; color: Theme.text; font.bold: true; font.pixelSize: 14 }

            RowLayout {
                Layout.fillWidth: true
                Text { text: "Base"; color: Theme.subText; Layout.preferredWidth: 60 }
                SliderBar {
                    Layout.fillWidth: true
                    value: appearanceConfig.transparencyBase
                    onMoved: (v) => appearanceConfig.transparencyBase = v
                }
                Text { text: appearanceConfig.transparencyBase.toFixed(2); color: Theme.text; Layout.preferredWidth: 40 }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "Layers"; color: Theme.subText; Layout.preferredWidth: 60 }
                SliderBar {
                    Layout.fillWidth: true
                    value: appearanceConfig.transparencyLayers
                    onMoved: (v) => appearanceConfig.transparencyLayers = v
                }
                Text { text: appearanceConfig.transparencyLayers.toFixed(2); color: Theme.text; Layout.preferredWidth: 40 }
            }
        }
    }

    // --- Dark theme toggle ---
    Rectangle {
        Layout.fillWidth: true
        height: 56
        radius: 12
        color: Theme.bg1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            Text { text: "Dark theme"; color: Theme.text; font.bold: true; Layout.fillWidth: true }
            ToggleSwitch {
                checked: wallpaperPage.isDark
                onToggled: (v) => wallpaperPage.setDark(v)
                
            }
        }
    }

    Item { Layout.preferredHeight: 8 }
}