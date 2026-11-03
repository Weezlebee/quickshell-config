import "../calculator"
import "../globalstate"
import "../settings"
import "../theme"
import "../top"
import "../widgets"
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

Variants {
    model: Quickshell.screens

    Item {
        id: screenRoot

        required property var modelData

        // ==========================================================
        // BOTTOM BAR
        // ==========================================================
        PanelWindow {
            id: bottomBarWindow

            screen: screenRoot.modelData
            implicitHeight: Theme.borderWidth + 12
            color: "transparent"
            exclusionMode: ExclusionMode.Auto
            WlrLayershell.keyboardFocus: launcherPopup.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors {
                bottom: true
                right: true
                left: true
            }

            // ==========================================================
            // GLOBAL SHORTCUT KEYBIND
            // ==========================================================
            GlobalShortcut {
                name: "AppLauncherToggle"
                onPressed: {
                    if (launcherPopup.visible)
                        launcherContent.closeWithAnimation();
                    else
                        launcherPopup.visible = true;
                }
            }

            Rectangle {
                id: barBackground

                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: Theme.borderWidth
                color: Theme.bg0

                // CENTER CLICK TARGET FOR THE LAUNCHER
                Item {
                    width: 200
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointerCursor
                        onClicked: {
                            if (launcherPopup.visible)
                                launcherContent.closeWithAnimation();
                            else
                                launcherPopup.visible = true;
                        }
                    }

                }

            }

            RoundedCorner {
                id: topLeftFillet

                anchors.bottom: barBackground.top
                anchors.left: barBackground.left
                color: Theme.bg0
                size: 12
                corner: 0
            }

            RoundedCorner {
                id: topRightFillet

                anchors.bottom: barBackground.top
                anchors.right: barBackground.right
                color: Theme.bg0
                size: 12
                corner: 1
            }

            // ==========================================================
            // LAUNCHER POPUP WINDOW
            // ==========================================================
            PopupWindow {
                id: launcherPopup

                anchor.window: bottomBarWindow
                implicitWidth: 850
                implicitHeight: 270
                anchor.rect.x: (screenRoot.modelData.width - implicitWidth) / 2 + 1275
                anchor.rect.y: 0
                anchor.rect.width: 1
                anchor.rect.height: bottomBarWindow.height
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Top
                anchor.margins.bottom: 8
                color: "transparent"
                visible: false

                AppLauncher {
                    id: launcherContent

                    anchors.fill: parent
                    onRequestClose: launcherPopup.visible = false
                }

            }

        }

        // ==========================================================
        // SETTINGS WINDOW (independent full-screen overlay, centered content)
        // ==========================================================
        PanelWindow {
            id: settingsWindow

            // Real visibility of the wayland surface. Only flips to false
            // once the shrink-out animation finishes, not immediately.
            property bool actuallyVisible: false

            screen: screenRoot.modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            visible: actuallyVisible
            WlrLayershell.keyboardFocus: actuallyVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                id: settingsScaleWrapper

                anchors.centerIn: parent
                width: 720
                height: 460
                opacity: 0

                SettingsPanel {
                    anchors.fill: parent
                    onRequestClose: GlobalStates.settingsOpen = false
                }

                transform: Scale {
                    id: settingsScale

                    origin.x: settingsScaleWrapper.width / 2
                    origin.y: settingsScaleWrapper.height / 2
                    xScale: 0.85
                    yScale: 0.85
                }

            }

            ParallelAnimation {
                id: growInAnimation

                NumberAnimation {
                    target: settingsScale
                    properties: "xScale,yScale"
                    from: 0.85
                    to: 1
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 4
                }

                NumberAnimation {
                    target: settingsScaleWrapper
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Easing.OutCubic
                }

            }

            SequentialAnimation {
                id: shrinkOutAnimation

                ParallelAnimation {
                    NumberAnimation {
                        target: settingsScale
                        properties: "xScale,yScale"
                        from: 1
                        to: 0.85
                        duration: 220
                        easing.type: Easing.InCubic
                    }

                    NumberAnimation {
                        target: settingsScaleWrapper
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 200
                        easing.type: Easing.InCubic
                    }

                }

                ScriptAction {
                    script: settingsWindow.actuallyVisible = false
                }

            }

            Connections {
                function onSettingsOpenChanged() {
                    if (GlobalStates.settingsOpen) {
                        settingsScale.xScale = 0.85;
                        settingsScale.yScale = 0.85;
                        settingsScaleWrapper.opacity = 0;
                        settingsWindow.actuallyVisible = true;
                        growInAnimation.restart();
                    } else {
                        if (settingsWindow.actuallyVisible)
                            shrinkOutAnimation.restart();

                    }
                }

                target: GlobalStates
            }

        }

        // ==========================================================
        // CALCULATOR WINDOW (independent full-screen overlay, centered content)
        // ==========================================================
        PanelWindow {
            id: calculatorWindow

            // Real visibility of the wayland surface. Only flips to false
            // once the shrink-out animation finishes, not immediately.
            property bool actuallyVisible: false

            screen: screenRoot.modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            visible: actuallyVisible
            WlrLayershell.keyboardFocus: actuallyVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Item {
                id: calculatorScaleWrapper

                anchors.centerIn: parent
                width: 720
                height: 460
                opacity: 0

                CalculatorPopup {
                    anchors.fill: parent
                    onRequestClose: GlobalStates.calculatorOpen = false
                }

                transform: Scale {
                    id: calculatorScale

                    origin.x: calculatorScaleWrapper.width / 2
                    origin.y: calculatorScaleWrapper.height / 2
                    xScale: 0.85
                    yScale: 0.85
                }

            }

            ParallelAnimation {
                id: calculatorGrowInAnimation

                NumberAnimation {
                    target: calculatorScale
                    properties: "xScale,yScale"
                    from: 0.85
                    to: 1
                    duration: 280
                    easing.type: Easing.OutBack
                    easing.overshoot: 4
                }

                NumberAnimation {
                    target: calculatorScaleWrapper
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 200
                    easing.type: Easing.OutCubic
                }

            }

            SequentialAnimation {
                id: calculatorShrinkOutAnimation

                ParallelAnimation {
                    NumberAnimation {
                        target: calculatorScale
                        properties: "xScale,yScale"
                        from: 1
                        to: 0.85
                        duration: 220
                        easing.type: Easing.InCubic
                    }

                    NumberAnimation {
                        target: calculatorScaleWrapper
                        property: "opacity"
                        from: 1
                        to: 0
                        duration: 200
                        easing.type: Easing.InCubic
                    }

                }

                ScriptAction {
                    script: calculatorWindow.actuallyVisible = false
                }

            }

            Connections {
                function onCalculatorOpenChanged() {
                    if (GlobalStates.calculatorOpen) {
                        calculatorScale.xScale = 0.85;
                        calculatorScale.yScale = 0.85;
                        calculatorScaleWrapper.opacity = 0;
                        calculatorWindow.actuallyVisible = true;
                        calculatorGrowInAnimation.restart();
                    } else {
                        if (calculatorWindow.actuallyVisible)
                            calculatorShrinkOutAnimation.restart();

                    }
                }

                target: GlobalStates
            }

        }

    }

}
 