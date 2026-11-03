pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

FileView {
    id: root
    path: Quickshell.env("HOME") + "/.config/quickshell/modules/settings/services_settings.json"
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    property alias weatherPollMinutes: adapter.weatherPollMinutes
    property alias batteryPollSeconds: adapter.batteryPollSeconds
    property alias lyricsBackend: adapter.lyricsBackend

    JsonAdapter {
        id: adapter
        property int weatherPollMinutes: 15
        property int batteryPollSeconds: 5
        property string lyricsBackend: "lrclib"
    }
}