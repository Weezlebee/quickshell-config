import QtQuick
import Quickshell.Services.Notifications

// Wrapper around a single Notification, created by Notifs.qml
QtObject {
    id: entry

    property Notification notification
    property bool popup: true
    readonly property date time: new Date()

    function dismiss() {
        if (entry.notification)
            entry.notification.dismiss();
        else
            Notifs.remove(entry);
    }

    function invokeDefault() {
        const actions = entry.notification ? entry.notification.actions : [];
        for (const a of actions) {
            if (a.identifier === "default") {
                a.invoke();
                return true;
            }
        }
        return false;
    }

    // The app (or we) closed it -> drop it from the list
    readonly property Connections _conn: Connections {
        target: entry.notification
        function onClosed() {
            Notifs.remove(entry);
        }
    }
}
