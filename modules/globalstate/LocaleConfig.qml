pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

FileView {
    id: root
    path: Quickshell.env("HOME") + "/.config/quickshell/modules/settings/language_settings.json"
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    property alias weatherLocation: adapter.weatherLocation
    property alias useFahrenheit: adapter.useFahrenheit
    property alias useTwelveHourClock: adapter.useTwelveHourClock

    JsonAdapter {
        id: adapter
        property string weatherLocation: "Boston, US"
        property bool useFahrenheit: false
        property bool useTwelveHourClock: false
    }
}