pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Owns the org.freedesktop.Notifications D-Bus name and keeps the list of
// notifications. `popups` is what the popup window shows; `list` keeps
// everything until dismissed (useful for a notification center later).
Singleton {
    id: root

    property var list: []
    readonly property var popups: list.filter(n => n.popup)

    property bool dnd: false
    property bool centerOpen: false
    property date now: new Date()   // ticks while the center is open, for "5m ago"
    readonly property int defaultTimeout: 5000   // ms, how long popups stay up
    readonly property bool respectAppTimeout: false

    function timeoutFor(n) {
        if (!respectAppTimeout || !n || n.expireTimeout <= 0)
            return defaultTimeout;
        // apps send this in different units; small numbers are seconds, big ones ms
        const ms = n.expireTimeout < 100 ? n.expireTimeout * 1000 : n.expireTimeout;
        return Math.max(2000, Math.min(ms, 15000));
    }
    readonly property int maxPopups: 5

    function remove(n) {
        root.list = root.list.filter(x => x !== n);
        n.destroy(1000); // delay so the card's exit animation can still read it
    }

    function clearAll() {
        for (const n of root.list.slice())
            n.dismiss();
    }

    // Opening the center takes over any visible popups
    onCenterOpenChanged: {
        now = new Date();
        if (centerOpen)
            for (const n of list)
                n.popup = false;
    }

    function timeAgo(t, ref) {
        if (!t)
            return "";
        const s = Math.floor((ref - t) / 1000);
        if (s < 60) return "now";
        if (s < 3600) return Math.floor(s / 60) + "m ago";
        if (s < 86400) return Math.floor(s / 3600) + "h ago";
        return Qt.formatDate(t, "MMM d");
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.centerOpen
        onTriggered: root.now = new Date()
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;

            const critical = notification.urgency === NotificationUrgency.Critical;
            const n = entryComp.createObject(root, {
                notification: notification,
                popup: !root.dnd || critical
            });
            root.list = [n].concat(root.list);
        }
    }

    Component {
        id: entryComp
        NotifEntry {}
    }

    // qs ipc call notifs clear | toggleDnd | dismissLatest
    IpcHandler {
        target: "notifs"

        function clear(): void {
            root.clearAll();
        }

        function toggleDnd(): void {
            root.dnd = !root.dnd;
        }

        function toggleCenter(): void {
            root.centerOpen = !root.centerOpen;
        }

        function dismissLatest(): void {
            if (root.list.length > 0)
                root.list[0].dismiss();
        }
    }
}
