import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import "../top"
import "../theme"

Item {
    id: root

    // Metrics Data Properties
    property real cpuUsage: 0
    property real gpuUsage: 0.05
    property real memUsedGiB: 0
    property real memTotalGiB: 16
    property real memPercent: 0
    property real diskUsedGiB: 0
    property real diskTotalGiB: 100
    property real diskPercent: 0
    property real netRxRateKB: 0
    property real netTxRateKB: 0
    property var lastCpuStats: null
    property var lastNetStats: null

    // History Tracking for Live Graphs (Caelestia Style)
    property var cpuHistory: []
    property var gpuHistory: []
    property var netRxHistory: []
    property var netTxHistory: []
    property int maxHistoryLength: 30

    function pushHistory(array, val) {
        var newArr = array.slice();
        newArr.push(val);
        if (newArr.length > maxHistoryLength)
            newArr.shift();
        return newArr;
    }

    signal requestClose()

    function closeWithAnimation() {
        slideInAnimation.restart();
    }

    implicitWidth: 140
    implicitHeight: 280

    onVisibleChanged: {
        if (visible)
            slideOutAnimation.restart();
    }
    Component.onCompleted: {
        if (visible)
            slideOutAnimation.restart();
    }

    // ==========================================================
    // DUAL DIRECTIONAL ANIMATION TIMELINES
    // ==========================================================
    ParallelAnimation {
        id: slideOutAnimation

        NumberAnimation {
            target: contentTranslation
            property: "x"
            from: -root.width
            to: 0
            duration: 600
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        id: slideInAnimation

        ParallelAnimation {
            NumberAnimation {
                target: contentTranslation
                property: "x"
                from: 0
                to: -root.width
                duration: 600
                easing.type: Easing.OutCubic
            }
        }

        ScriptAction {
            script: root.requestClose()
        }
    }

    // ==========================================================
    // ANIMATED CONTENT WRAPPER
    // ==========================================================
    Item {
        id: animatedContent

        anchors.fill: parent
        opacity: 1

        transform: Translate {
            id: contentTranslation
            x: -root.width
        }

        // ==========================================================
        // TOP & BOTTOM LEFT CONCAVE FILLETS (FLUSH TO BAR)
        // ==========================================================
        RoundedCorner {
            anchors.bottom: mainPanel.top
            anchors.left: mainPanel.left
            color: Theme.bg0
            size: 12
            corner: 0 // Bottom-Left carved out for top concave fillet
            z: 10
        }

        RoundedCorner {
            anchors.top: mainPanel.bottom
            anchors.left: mainPanel.left
            color: Theme.bg0
            size: 12
            corner: 3 // Top-Left carved out for bottom concave fillet
            z: 10
        }

        Rectangle {
            id: mainPanel

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            anchors.leftMargin: 0 // NO GAP on the left

            color: Theme.bg0
            // Right corners rounded only
            topLeftRadius: 0
            bottomLeftRadius: 0
            topRightRadius: 18
            bottomRightRadius: 18
            clip: true

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                // ==========================================================
                // >>> COMPACT TAB HEADER WITH CLICKABLE DOTS <<<
                // ==========================================================
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4

                    // Clickable Indicator Dots Row
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 6

                        Repeater {
                            model: 3

                            delegate: Rectangle {
                                width: index === perfSwipeView.currentIndex ? 14 : 6
                                height: 6
                                radius: 3
                                color: index === perfSwipeView.currentIndex ? Theme.rose : "#cbd5e1"

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointerCursor
                                    onClicked: perfSwipeView.currentIndex = index
                                }

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 200
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                            }
                        }
                    }

                    // Active Page Title
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: perfSwipeView.currentIndex === 0 ? "Processor" : (perfSwipeView.currentIndex === 1 ? "Memory" : "Network")
                        color: Theme.rose

                        font {
                            pixelSize: 11
                            bold: true
                        }
                    }
                }

                // ==========================================================
                // >>> SWIPE VIEWS <<<
                // ==========================================================
                SwipeView {
                    id: perfSwipeView

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // ------------------------------------------------------
                    // PAGE 1: CPU & GPU (WITH LIVE AREA GRAPHS)
                    // ------------------------------------------------------
                    Rectangle {
                        color: Theme.bg1
                        radius: 12

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            // CPU Block
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2

                                Text {
                                    text: "💻 CPU"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.text
                                }

                                Text {
                                    text: Math.round(root.cpuUsage * 100) + "%"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: Theme.rose
                                }

                                Canvas {
                                    id: cpuGraphCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    implicitHeight: 28

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        var data = root.cpuHistory;
                                        if (!data || data.length < 2) return;

                                        var w = width;
                                        var h = height;
                                        var step = w / (root.maxHistoryLength - 1);

                                        // Area Gradient
                                        var grad = ctx.createLinearGradient(0, 0, 0, h);
                                        grad.addColorStop(0, Qt.rgba(0.92, 0.43, 0.57, 0.4));
                                        grad.addColorStop(1, Qt.rgba(0.92, 0.43, 0.57, 0.0));

                                        ctx.beginPath();
                                        ctx.moveTo(0, h);
                                        for (var i = 0; i < data.length; i++) {
                                            ctx.lineTo(i * step, h - (data[i] * h));
                                        }
                                        ctx.lineTo((data.length - 1) * step, h);
                                        ctx.closePath();
                                        ctx.fillStyle = grad;
                                        ctx.fill();

                                        // Top Stroke Line
                                        ctx.beginPath();
                                        for (var j = 0; j < data.length; j++) {
                                            var x = j * step;
                                            var y = h - (data[j] * h);
                                            if (j === 0) ctx.moveTo(x, y);
                                            else ctx.lineTo(x, y);
                                        }
                                        ctx.strokeStyle = Theme.rose;
                                        ctx.lineWidth = 1.5;
                                        ctx.stroke();
                                    }

                                    Connections {
                                        target: root
                                        function onCpuHistoryChanged() { cpuGraphCanvas.requestPaint(); }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.text
                            }

                            // GPU Block
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2

                                Text {
                                    text: "🖥️ GPU"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.text
                                }

                                Text {
                                    text: Math.round(root.gpuUsage * 100) + "%"
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: Theme.rose
                                }

                                Canvas {
                                    id: gpuGraphCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    implicitHeight: 28

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        var data = root.gpuHistory;
                                        if (!data || data.length < 2) return;

                                        var w = width;
                                        var h = height;
                                        var step = w / (root.maxHistoryLength - 1);

                                        var grad = ctx.createLinearGradient(0, 0, 0, h);
                                        grad.addColorStop(0, Qt.rgba(0.92, 0.43, 0.57, 0.4));
                                        grad.addColorStop(1, Qt.rgba(0.92, 0.43, 0.57, 0.0));

                                        ctx.beginPath();
                                        ctx.moveTo(0, h);
                                        for (var i = 0; i < data.length; i++) {
                                            ctx.lineTo(i * step, h - (data[i] * h));
                                        }
                                        ctx.lineTo((data.length - 1) * step, h);
                                        ctx.closePath();
                                        ctx.fillStyle = grad;
                                        ctx.fill();

                                        ctx.beginPath();
                                        for (var j = 0; j < data.length; j++) {
                                            var x = j * step;
                                            var y = h - (data[j] * h);
                                            if (j === 0) ctx.moveTo(x, y);
                                            else ctx.lineTo(x, y);
                                        }
                                        ctx.strokeStyle = Theme.rose;
                                        ctx.lineWidth = 1.5;
                                        ctx.stroke();
                                    }

                                    Connections {
                                        target: root
                                        function onGpuHistoryChanged() { gpuGraphCanvas.requestPaint(); }
                                    }
                                }
                            }
                        }
                    }

                    // ------------------------------------------------------
                    // PAGE 2: MEMORY & STORAGE
                    // ------------------------------------------------------
                    Rectangle {
                        color: Theme.bg1
                        radius: 12

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 4

                            // Memory Section
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2

                                Text {
                                    text: "🧠 Memory"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.rose
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Canvas {
                                        id: memCanvas

                                        anchors.fill: parent
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.reset();
                                            var cx = width / 2;
                                            var cy = height / 2;
                                            var r = Math.min(width, height) / 2 - 8;
                                            ctx.beginPath();
                                            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                                            ctx.lineWidth = 8;
                                            ctx.strokeStyle = Theme.text;
                                            ctx.stroke();
                                            ctx.beginPath();
                                            ctx.arc(cx, cy, r, -Math.PI / 2, (-Math.PI / 2) + (root.memPercent * 2 * Math.PI));
                                            ctx.lineWidth = 7;
                                            ctx.strokeStyle = Theme.rose;
                                            ctx.lineCap = "round";
                                            ctx.stroke();
                                        }

                                        Connections {
                                            function onMemPercentChanged() {
                                                memCanvas.requestPaint();
                                            }

                                            target: root
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: Math.round(root.memPercent * 100) + "%"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.rose
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.memUsedGiB.toFixed(1) + "/" + root.memTotalGiB.toFixed(0) + "G"
                                    font.pixelSize: 9
                                    color: Theme.text
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.text
                            }

                            // Storage Section
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2

                                Text {
                                    text: "💽 Storage"
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: Theme.text
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Canvas {
                                        id: diskCanvas

                                        anchors.fill: parent
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.reset();
                                            var cx = width / 2;
                                            var cy = height / 2;
                                            var r = Math.min(width, height) / 2 - 8;
                                            ctx.beginPath();
                                            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                                            ctx.lineWidth = 8;
                                            ctx.strokeStyle = Theme.text;
                                            ctx.stroke();
                                            ctx.beginPath();
                                            ctx.arc(cx, cy, r, -Math.PI / 2, (-Math.PI / 2) + (root.diskPercent * 2 * Math.PI));
                                            ctx.lineWidth = 7;
                                            ctx.strokeStyle = Theme.pine;
                                            ctx.lineCap = "round";
                                            ctx.stroke();
                                        }

                                        Connections {
                                            function onDiskPercentChanged() {
                                                diskCanvas.requestPaint();
                                            }

                                            target: root
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: Math.round(root.diskPercent * 100) + "%"
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.pine
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root.diskUsedGiB.toFixed(0) + "/" + root.diskTotalGiB.toFixed(0) + "G"
                                    font.pixelSize: 9
                                    color: Theme.text
                                }
                            }
                        }
                    }

                    // ------------------------------------------------------
                    // PAGE 3: NETWORK (WITH LIVE THROUGHPUT GRAPHS)
                    // ------------------------------------------------------
                    Rectangle {
                        color: Theme.bg1
                        radius: 12

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6

                            Text {
                                text: "⇅ Network"
                                font.pixelSize: 11
                                font.bold: true
                                color: Theme.rose
                            }

                            // Download
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2

                                Text {
                                    text: "↓ Download"
                                    font.pixelSize: 10
                                    color: Theme.text
                                }

                                Text {
                                    text: root.netRxRateKB.toFixed(1) + " KB/s"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.iris
                                }

                                Canvas {
                                    id: netRxCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    implicitHeight: 24

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        var data = root.netRxHistory;
                                        if (!data || data.length < 2) return;

                                        var maxVal = Math.max.apply(null, data);
                                        if (maxVal <= 0) maxVal = 1;

                                        var w = width;
                                        var h = height;
                                        var step = w / (root.maxHistoryLength - 1);

                                        var grad = ctx.createLinearGradient(0, 0, 0, h);
                                        grad.addColorStop(0, Qt.rgba(0.77, 0.65, 0.91, 0.4));
                                        grad.addColorStop(1, Qt.rgba(0.77, 0.65, 0.91, 0.0));

                                        ctx.beginPath();
                                        ctx.moveTo(0, h);
                                        for (var i = 0; i < data.length; i++) {
                                            ctx.lineTo(i * step, h - ((data[i] / maxVal) * h));
                                        }
                                        ctx.lineTo((data.length - 1) * step, h);
                                        ctx.closePath();
                                        ctx.fillStyle = grad;
                                        ctx.fill();

                                        ctx.beginPath();
                                        for (var j = 0; j < data.length; j++) {
                                            var x = j * step;
                                            var y = h - ((data[j] / maxVal) * h);
                                            if (j === 0) ctx.moveTo(x, y);
                                            else ctx.lineTo(x, y);
                                        }
                                        ctx.strokeStyle = Theme.iris;
                                        ctx.lineWidth = 1.5;
                                        ctx.stroke();
                                    }

                                    Connections {
                                        target: root
                                        function onNetRxHistoryChanged() { netRxCanvas.requestPaint(); }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.text
                            }

                            // Upload
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2

                                Text {
                                    text: "↑ Upload"
                                    font.pixelSize: 10
                                    color: Theme.text
                                }

                                Text {
                                    text: root.netTxRateKB.toFixed(1) + " KB/s"
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.iris
                                }

                                Canvas {
                                    id: netTxCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    implicitHeight: 24

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.reset();
                                        var data = root.netTxHistory;
                                        if (!data || data.length < 2) return;

                                        var maxVal = Math.max.apply(null, data);
                                        if (maxVal <= 0) maxVal = 1;

                                        var w = width;
                                        var h = height;
                                        var step = w / (root.maxHistoryLength - 1);

                                        var grad = ctx.createLinearGradient(0, 0, 0, h);
                                        grad.addColorStop(0, Qt.rgba(0.77, 0.65, 0.91, 0.4));
                                        grad.addColorStop(1, Qt.rgba(0.77, 0.65, 0.91, 0.0));

                                        ctx.beginPath();
                                        ctx.moveTo(0, h);
                                        for (var i = 0; i < data.length; i++) {
                                            ctx.lineTo(i * step, h - ((data[i] / maxVal) * h));
                                        }
                                        ctx.lineTo((data.length - 1) * step, h);
                                        ctx.closePath();
                                        ctx.fillStyle = grad;
                                        ctx.fill();

                                        ctx.beginPath();
                                        for (var j = 0; j < data.length; j++) {
                                            var x = j * step;
                                            var y = h - ((data[j] / maxVal) * h);
                                            if (j === 0) ctx.moveTo(x, y);
                                            else ctx.lineTo(x, y);
                                        }
                                        ctx.strokeStyle = Theme.iris;
                                        ctx.lineWidth = 1.5;
                                        ctx.stroke();
                                    }

                                    Connections {
                                        target: root
                                        function onNetTxHistoryChanged() { netTxCanvas.requestPaint(); }
                                    }
                                }
                            }
                        }
                    }

                    Behavior on currentIndex {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }

    // Scroll Wheel Page Switching
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            if (event.angleDelta.y < 0 || event.angleDelta.x < 0) {
                if (perfSwipeView.currentIndex < perfSwipeView.count - 1)
                    perfSwipeView.currentIndex++;
            } else {
                if (perfSwipeView.currentIndex > 0)
                    perfSwipeView.currentIndex--;
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            cpuProc.running = true;
            memProc.running = true;
            diskProc.running = true;
            netProc.running = true;

            // Maintain GPU synthetic history push
            root.gpuHistory = root.pushHistory(root.gpuHistory, root.gpuUsage);
        }
    }

    // --- SYSTEM METRIC PROCESSES ---
    Process {
        id: cpuProc

        command: ["cat", "/proc/stat"]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith("cpu ")) {
                        var parts = lines[i].trim().split(/\s+/).slice(1).map(Number);
                        var idle = parts[3] + parts[4];
                        var total = parts.reduce((a, b) => {
                            return a + b;
                        }, 0);
                        if (root.lastCpuStats) {
                            var totalDiff = total - root.lastCpuStats.total;
                            var idleDiff = idle - root.lastCpuStats.idle;
                            if (totalDiff > 0) {
                                root.cpuUsage = (totalDiff - idleDiff) / totalDiff;
                                root.cpuHistory = root.pushHistory(root.cpuHistory, root.cpuUsage);
                            }
                        }
                        root.lastCpuStats = {
                            "total": total,
                            "idle": idle
                        };
                        break;
                    }
                }
            }
        }
    }

    Process {
        id: memProc

        command: ["cat", "/proc/meminfo"]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n");
                var total = 0, avail = 0;
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].startsWith("MemTotal:"))
                        total = parseInt(lines[i].replace(/[^0-9]/g, ""));

                    if (lines[i].startsWith("MemAvailable:"))
                        avail = parseInt(lines[i].replace(/[^0-9]/g, ""));
                }
                if (total > 0) {
                    var used = total - avail;
                    root.memTotalGiB = total / 1024 / 1024;
                    root.memUsedGiB = used / 1024 / 1024;
                    root.memPercent = used / total;
                }
            }
        }
    }

    Process {
        id: diskProc

        command: ["df", "-k", "/"]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n");
                if (lines.length > 1) {
                    var parts = lines[1].trim().split(/\s+/);
                    if (parts.length >= 4) {
                        var totalK = parseInt(parts[1]);
                        var usedK = parseInt(parts[2]);
                        if (totalK > 0) {
                            root.diskTotalGiB = totalK / 1024 / 1024;
                            root.diskUsedGiB = usedK / 1024 / 1024;
                            root.diskPercent = usedK / totalK;
                        }
                    }
                }
            }
        }
    }

    Process {
        id: netProc

        command: ["cat", "/proc/net/dev"]

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split("\n");
                var rx = 0, tx = 0;
                for (var i = 2; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (!line || line.startsWith("lo:"))
                        continue;

                    var parts = line.split(/\s+/);
                    if (parts.length >= 10) {
                        rx += parseInt(parts[1]) || 0;
                        tx += parseInt(parts[9]) || 0;
                    }
                }
                var now = Date.now();
                if (root.lastNetStats) {
                    var dt = (now - root.lastNetStats.time) / 1000;
                    if (dt > 0) {
                        root.netRxRateKB = Math.max(0, (rx - root.lastNetStats.rx) / 1024 / dt);
                        root.netTxRateKB = Math.max(0, (tx - root.lastNetStats.tx) / 1024 / dt);

                        root.netRxHistory = root.pushHistory(root.netRxHistory, root.netRxRateKB);
                        root.netTxHistory = root.pushHistory(root.netTxHistory, root.netTxRateKB);
                    }
                }
                root.lastNetStats = {
                    "rx": rx,
                    "tx": tx,
                    "time": now
                };
            }
        }
    }
}