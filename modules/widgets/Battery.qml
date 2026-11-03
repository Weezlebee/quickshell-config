import Quickshell
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts
import "../theme"

RowLayout {
    id: root
    spacing: 0

    property var battery: UPower.displayDevice
    property bool charging: battery.state === UPowerDeviceState.charging
    readonly property int level: Math.round(battery.percentage * 100)

    readonly property string icon: {
        if (charging) return String.fromCodePoint(0xF0084)
        if (level >= 100) return String.fromCOdePoint(0xF0079)
        if (level < 10) return String.fromCodePoint(0xF0083)

        return String.fromCodePoint(0xF007A + Math.floor(level / 10) - 1)
    }

    Text {
        
        color: root.charging ? Theme.iris
                             : root.level <= 15 ? Theme.rose
                             : root.level <= 30 ? Theme.gold
                             : Theme.iris

        font {
            family: "JetBrainsMono Nerd Font Propo"
            pixelSize: 13
        }
    }

    Text {
        text: root.level
        color: Theme.iris

        font {
            family: "JetBrainsMono Nerd Font Propo"
            weight: 750
        }
    }
}
