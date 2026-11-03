pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../theme"
import "../globalstate"
import "./"

ColumnLayout {
    id: languagePage
    spacing: 14

    // --- Weather location ---
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 90
        radius: 12
        color: Theme.bg1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Text { text: "Weather location"; color: Theme.text; font.bold: true; font.pixelSize: 14 }

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: 8
                color: Theme.bg0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10

                    TextField {
                        id: locationField
                        Layout.fillWidth: true
                        text: LocaleConfig.weatherLocation
                        placeholderText: "City, Country (e.g. London, UK)"
                        color: Theme.text
                        placeholderTextColor: Theme.subText
                        background: Rectangle { color: "transparent" }
                        font.pixelSize: 12
                        onEditingFinished: LocaleConfig.weatherLocation = text
                    }
                }
            }
        }
    }

    // --- Units ---
    Rectangle {
        Layout.fillWidth: true
        height: 56
        radius: 12
        color: Theme.bg1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text { text: "Use Fahrenheit"; color: Theme.text; font.bold: true; font.pixelSize: 14 }
                Text { text: "Show temperature in °F instead of °C"; color: Theme.subText; font.pixelSize: 11 }
            }

            ToggleSwitch {
                checked: LocaleConfig.useFahrenheit
                onToggled: (v) => LocaleConfig.useFahrenheit = v
            }
        }
    }

    // --- Clock format ---
    Rectangle {
        Layout.fillWidth: true
        height: 56
        radius: 12
        color: Theme.bg1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            ColumnLayout {
                spacing: 0
                Layout.fillWidth: true
                Text { text: "12-hour clock"; color: Theme.text; font.bold: true; font.pixelSize: 14 }
                Text { text: "Show time as 1:00 PM instead of 13:00"; color: Theme.subText; font.pixelSize: 11 }
            }

            ToggleSwitch {
                checked: LocaleConfig.useTwelveHourClock
                onToggled: (v) => LocaleConfig.useTwelveHourClock = v
            }
        }
    }

    Item { Layout.fillHeight: true }
}