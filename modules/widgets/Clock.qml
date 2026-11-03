import QtQuick
import Quickshell
import "../theme"
import "../globalstate"

Text {
    text: Qt.formatDateTime(clock.date, LocaleConfig.useTwelveHourClock ? "h:mm AP" : "hh:mm")
    color: Theme.text

    font {
        family: "JetBrainsMono Nerd Font Propo"
        letterSpacing: -1
        pixelSize: 15
        weight: 750
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}