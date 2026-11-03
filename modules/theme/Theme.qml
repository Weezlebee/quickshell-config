pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: theme

    // Stores the raw text ("dark" or "light")
    property string currentMode: "dark"

    // Helper boolean
    readonly property bool isDarkMode: currentMode.trim() !== "light"

    // --- Dynamic Theme Colors ---
    readonly property color bg0: isDarkMode ? "#191724" : "#faf4ed"
    readonly property color bg1: isDarkMode ? "#26233a" : "#f0e9e1"
    readonly property color bg2: isDarkMode ? "#212230" : "#9893a5"
    readonly property color bg3: isDarkMode ? "#312f44" : "#9993a5"
    readonly property color border: isDarkMode ? "#2f2a40" : "#dfdad9"
    readonly property color text: isDarkMode ? "#e0def4" : "#464261"
    readonly property color grey0: isDarkMode ? "#524f67" : "#9893a5"
    readonly property color grey1: isDarkMode ? "#44475a" : "#9893a5"
    readonly property color subText: isDarkMode ? "#908caa" : "#797593"
    readonly property color placeholder: isDarkMode ? "#56526e" : "#9893a5"
    readonly property color highlight: isDarkMode ? "#ffffff" : "#000000"
    readonly property color hover: isDarkMode ? "rgba(255, 255, 255, 0.06)" : "rgba(0, 0, 0, 0.06)"
    readonly property color iris: isDarkMode ? "#c4a7e7" : "#907aa9"
    readonly property color rose: isDarkMode ? "#eb6f92" : "#b4637a"
    readonly property color love: isDarkMode ? "#ebbcba" : "#d7827e"
    readonly property color gold: isDarkMode ? "#f6c177" : "#ea9d34"
    readonly property color pine: isDarkMode ? "#31748f" : "#286983"
    readonly property color foam: isDarkMode ? "#9ccfd8" : "#56949f"

    readonly property var homeworkClasses: [ "Math", "English", "Science", "History" ] 
    readonly property var homeworkColors: ({ "Math": "#c4a7e7", "English": "#eb6f92", "Science": "#9ccfd8", "History": "#f6c177" })


    // Geometry
    readonly property int borderWidth: 8
    readonly property int radius: 24
    readonly property int margin: 8
    readonly property int topBarHeight: 25

    // File watcher to listen for live updates
    property var _fileWatcher: Scope {
        FileView {
            id: modeFileReader
            path: Quickshell.env("HOME") + "/.config/appearance/theme/mode"
            watchChanges: true

            onTextChanged: {
                theme.currentMode = modeFileReader.text().trim();
                console.log("Theme.qml updated mode to:", theme.currentMode);
            }

            onFileChanged: this.reload()
        }
    }
}