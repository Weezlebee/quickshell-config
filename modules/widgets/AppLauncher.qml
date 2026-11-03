pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "../top"
import "../theme"
import "../globalstate"
import "./" 
import "../settings"

Item {
    id: launcherRoot

    readonly property bool isWallpaperMode: query.trim().startsWith(">wallpaper")
    readonly property bool isActionMode: query.trim().startsWith(">") && !isWallpaperMode

    readonly property int targetWidth: isWallpaperMode ? 850 : 230

    implicitWidth: 850
    implicitHeight: 520

    signal requestClose()

    property string query: ""
    property string activeTheme: themeFileReader.text().trim() || "main"
    property bool isDarkMode: modeFileReader.text().trim() !== "light"

    // --- Dynamic Light / Dark Mode Color Palette ---
    readonly property color bgColor: Theme.bg0
    readonly property color cardBgColor: Theme.bg1
    readonly property color hoverBgColor: Theme.hover
    readonly property color textColor: Theme.text
    readonly property color subTextColor: Theme.subText
    readonly property color placeholderColor: Theme.placeholder
    readonly property color highlightColor: Theme.highlight

    property var pinnedApps: [
        "LibreWolf", "Spotify", 
        "PrusaSlicer", "IntelliJ IDEA Community Edition", 
        "GPU Screen Recorder", "Google Chrome",
        "Modrinth App", "Steam", "Zoom Workplace"
    ]

    property var actionCommands: [
        { name: "> wallpaper", comment: "Browse and set desktop wallpaper", action: "wallpaper" },
        { name: "> darkmode", comment: "Toggle light / dark mode theme", action: "darkmode" },
        { name: "> settings", comment: "Open system settings", action: "settings" },
        { name: "> calculator", comment: "Open scientific graphing calculator", action: "calculator" }
    ]

    // Reading current theme and mode dynamically from disk
    Scope {
        FileView {
            id: themeFileReader
            path: Quickshell.env("HOME") + "/.config/appearance/theme/which_theme"
            watchChanges: true
            onFileChanged: this.reload()
        }

        FileView {
            id: modeFileReader
            path: Quickshell.env("HOME") + "/.config/appearance/theme/mode"
            watchChanges: true
            onFileChanged: this.reload()
        }

        Component.onCompleted: {
            console.log("Active theme loaded:", launcherRoot.activeTheme)
        }
    }

    function setWallpaper(fileName) {
        if (!fileName) {
            console.warn("setWallpaper called with empty filename!");
            return;
        }

        const basePath = Quickshell.env("HOME") + "/Pictures/wallpapers/main/";
        const fullPath = basePath + fileName;
        console.log("Setting wallpaper:", fullPath); // sanity check

        Quickshell.execDetached([
            "awww", "img", fullPath,
            "--transition-type", "random"
        ]);

        launcherRoot.closeWithAnimation();
    }


    function launchSelected() {
        if (isWallpaperMode) {
            if (wallpaperListView.currentItem) {
                let name = wallpaperListView.currentItem.fileName;
                setWallpaper(name);
            }
            return;
        }

        if (resultsListView.currentItem && resultsListView.currentItem.modelData) {
            let item = resultsListView.currentItem.modelData;

            if (item.action === "darkmode") {
                let toggleScript = Quickshell.env("HOME") + "/.config/quickshell/modules/scripts/toggle_mode.sh";
                Quickshell.execDetached([toggleScript]);
                launcherRoot.closeWithAnimation();
            } else if (item.action === "wallpaper") {
                mainSearchField.text = ">wallpaper ";
            } else if (item.action === "settings") {
                GlobalStates.settingsOpen = true;
                launcherRoot.closeWithAnimation();
            } else if (item.action === "calculator") {
                GlobalStates.calculatorOpen = true;
                launcherRoot.closeWithAnimation();
            } else if (item.execute) {
                item.execute();
                launcherRoot.closeWithAnimation();
            }
        }
    }

    function closeWithAnimation() {
        slideDownAnimation.restart();
    }

    FolderListModel {
        id: wallpaperFolderModel
        folder: "file://" + Quickshell.env("HOME") + "/Pictures/wallpapers/" + launcherRoot.activeTheme
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif"]
        showDirs: false
    }

    ScriptModel {
        id: filteredApps
        values: {
            const q = launcherRoot.query.trim().toLowerCase();

            if (q.startsWith(">")) {
                const subQuery = q.substring(1).trim();
                return actionCommands.filter(a => a.name.toLowerCase().includes(subQuery));
            }

            const all = [...DesktopEntries.applications.values].filter(d => d.name);
            all.sort((a, b) => {
                let idxA = launcherRoot.pinnedApps.indexOf(a.name);
                let idxB = launcherRoot.pinnedApps.indexOf(b.name);
                if (idxA !== -1 && idxB !== -1) return idxA - idxB;
                if (idxA !== -1) return -1;
                if (idxB !== -1) return 1;
                return a.name.localeCompare(b.name);
            });

            if (q === "") return all;

            return all.filter(d => {
                const name = (d.name || "").toLowerCase();
                const comment = (d.comment || "").toLowerCase();
                const keywords = (d.keywords || []).join(" ").toLowerCase();
                return name.includes(q) || comment.includes(q) || keywords.includes(q);
            });
        }
    }

    ParallelAnimation {
        id: slideUpAnimation
        NumberAnimation { 
            target: contentTranslation; property: "y"
            from: launcherRoot.height; to: 0
            duration: 500; easing.type: Easing.OutCubic 
        }
    }

    SequentialAnimation {
        id: slideDownAnimation
        ParallelAnimation {
            NumberAnimation { 
                target: contentTranslation; property: "y"
                from: 0; to: launcherRoot.height
                duration: 500; easing.type: Easing.InCubic 
            }
        }
        ScriptAction { script: launcherRoot.requestClose() }
    }

    Item {
        id: animatedContent
        anchors.fill: parent
        transform: Translate { id: contentTranslation; y: launcherRoot.height }

        Item {
            id: visualContainer
            height: parent.height
            width: launcherRoot.targetWidth
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on width {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }

            RoundedCorner {
                anchors.bottom: menuBody.bottom
                anchors.right: menuBody.left
                color: Theme.bg0; size: 12; corner: 1; z: 10
            }

            RoundedCorner {
                anchors.bottom: menuBody.bottom
                anchors.left: menuBody.right
                color: Theme.bg0; size: 12; corner: 0; z: 10
            }

            Rectangle {
                id: menuBody
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                color: launcherRoot.bgColor
                topLeftRadius: 16
                topRightRadius: 16
                clip: true

                Behavior on color {
                    ColorAnimation { duration: 200 }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // 1. STANDARD APP/COMMAND LIST
                    ListView {
                        id: resultsListView
                        visible: !launcherRoot.isWallpaperMode
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 4
                        clip: true

                        model: filteredApps.values
                        currentIndex: filteredApps.values.length > 0 ? 0 : -1
                        keyNavigationWraps: true
                        highlightFollowsCurrentItem: false

                        highlight: Rectangle {
                            radius: 10
                            color: launcherRoot.highlightColor
                            opacity: 0.08
                            y: resultsListView.currentItem ? resultsListView.currentItem.y : 0
                            width: ListView.view.width
                            height: 52
                            Behavior on y { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                        }

                        delegate: ItemDelegate {
                            id: appDelegate
                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            height: 52

                            background: Rectangle {
                                color: appDelegate.hovered ? launcherRoot.hoverBgColor : "transparent"
                                radius: 10
                            }

                            contentItem: RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 12

                                Rectangle {
                                    width: 36; height: 36
                                    color: launcherRoot.isActionMode ? "#31748f" : launcherRoot.cardBgColor
                                    radius: 8

                                    IconImage {
                                        anchors.centerIn: parent
                                        width: 24; height: 24
                                        source: appDelegate.modelData.icon 
                                            ? Quickshell.iconPath(appDelegate.modelData.icon, true)
                                            : ""
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: appDelegate.modelData.name || ""
                                        font.pixelSize: 14; font.bold: true
                                        color: launcherRoot.textColor
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: appDelegate.modelData.comment || ""
                                        font.pixelSize: 11
                                        color: launcherRoot.subTextColor
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            onClicked: {
                                resultsListView.currentIndex = appDelegate.index;
                                launcherRoot.launchSelected();
                            }
                        }
                    }

                    // 2. HORIZONTAL WALLPAPER LIST
                    ListView {
                        id: wallpaperListView
                        visible: launcherRoot.isWallpaperMode
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        orientation: ListView.Horizontal
                        spacing: 14
                        clip: true

                        model: wallpaperFolderModel
                        currentIndex: wallpaperFolderModel.count > 0 ? 0 : -1

                        delegate: WallpaperItem {
                            onSelected: (fileName) => {
                                wallpaperListView.currentIndex = index;
                                launcherRoot.setWallpaper(fileName);
                            }
                        }
                    }

                    // SEARCH FIELD
                    Rectangle {
                        id: searchBarContainer
                        Layout.fillWidth: true
                        height: 44
                        color: launcherRoot.cardBgColor
                        radius: 12

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14

                            TextField {
                                id: mainSearchField
                                Layout.fillWidth: true
                                placeholderText: 'Search applications or type ">" for commands...'
                                placeholderTextColor: launcherRoot.placeholderColor
                                color: launcherRoot.textColor
                                font.pixelSize: 14
                                background: Rectangle { color: "transparent" }
                                focus: true

                                onTextChanged: {
                                    launcherRoot.query = text;
                                    if (!launcherRoot.isWallpaperMode) {
                                        resultsListView.currentIndex = filteredApps.values.length > 0 ? 0 : -1;
                                    } else {
                                        wallpaperListView.currentIndex = wallpaperFolderModel.count > 0 ? 0 : -1;
                                    }
                                }

                                Keys.onEscapePressed: launcherRoot.closeWithAnimation()
                                Keys.onLeftPressed: {
                                    if (launcherRoot.isWallpaperMode && wallpaperListView.currentIndex > 0)
                                        wallpaperListView.currentIndex--;
                                }
                                Keys.onRightPressed: {
                                    if (launcherRoot.isWallpaperMode && wallpaperListView.currentIndex < wallpaperListView.count - 1)
                                        wallpaperListView.currentIndex++;
                                }
                                Keys.onUpPressed: {
                                    if (!launcherRoot.isWallpaperMode && resultsListView.currentIndex > 0)
                                        resultsListView.currentIndex--;
                                }
                                Keys.onDownPressed: {
                                    if (!launcherRoot.isWallpaperMode && resultsListView.currentIndex < resultsListView.count - 1)
                                        resultsListView.currentIndex++;
                                }
                                Keys.onReturnPressed: launcherRoot.launchSelected()
                                Keys.onEnterPressed: launcherRoot.launchSelected()
                            }
                        }
                    }
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            mainSearchField.text = "";
            slideUpAnimation.restart();
            mainSearchField.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        if (visible) {
            slideUpAnimation.restart();
            mainSearchField.forceActiveFocus();
        }
    }
}