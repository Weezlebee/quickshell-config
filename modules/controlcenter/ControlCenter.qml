import "../theme"
import "../top"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Io

Item {
    // ==========================================================
    // CONCAVE FILLETS (top corners where popup meets the bar above)
    // ==========================================================
    // ANIMATION END

    id: rootPanel

    property string activeWifi: "Disconnected"
    property var wifiNetworks: []
    property bool isScanning: false
    // Proportional sizing basis - Adjusted for 5 tabs safely
    property real scaleFactor: height / 420
    property int rowHeight: Math.max(28, Math.round(40 * scaleFactor))
    property int rowSpacing: Math.max(3, Math.round(6 * scaleFactor))
    property int headerMargin: 10
    property int titleFontSize: 11
    property int rowFontSize: Math.max(10, Math.round(13 * scaleFactor))
    // Password prompt state
    property string pendingSsid: ""
    property bool connecting: false
    property string connectError: ""
    // Calendar Properties
    property date currentDate: new Date()
    property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    property var calendarDays: []
    // Sound Levels (Values ranging from 0.0 to 1.0)
    property real volumeLevel: 0.5
    property real micLevel: 0.3
    // Real System Battery State Properties
    property int batteryPercentage: 100
    property string batteryState: "discharging"
    property real batteryEnergyRate: 0
    property string batteryTimeRemaining: ""
    // ==========================================================
    // >>> ANIMATION BLOCK START <
    // Caelestia Shell Style: Vertical Slide + Fade
    // ==========================================================
    property bool animateOpen: false
    // How long the close transition takes - the *caller* (whatever
    // window/loader hosts this panel) MUST wait this long before it
    // actually hides/destroys the panel, or the animation below will
    // never be seen. See requestClose() / closed signal below.
    readonly property int closeDuration: 550

    // Emitted once the close transition has fully finished playing.
    // The parent PanelWindow/Loader should listen for this and only
    // THEN set visible:false / destroy the item - never before.
    signal closed()

    // Call this instead of directly hiding the panel. It plays the
    // reverse animation first, then tells the caller it's safe to
    // actually close.
    function requestClose() {
        animateOpen = false;
        closeTimer.restart();
    }

    // Native System Audio Sync Functions
    function setSystemVolume(level) {
        var volumeCmd = Qt.createQmlObject('import Quickshell.Io; Process {}', rootPanel);
        var percentage = Math.round(level * 100) + "%";
        volumeCmd.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", percentage];
        volumeCmd.running = true;
    }

    function setSystemMicrophone(level) {
        var micCmd = Qt.createQmlObject('import Quickshell.Io; Process {}', rootPanel);
        var percentage = Math.round(level * 100) + "%";
        micCmd.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", percentage];
        micCmd.running = true;
    }

    function generateCalendar() {
        var year = currentDate.getFullYear();
        var month = currentDate.getMonth();
        var firstDay = new Date(year, month, 1).getDay();
        var totalDays = new Date(year, month + 1, 0).getDate();
        var prevTotalDays = new Date(year, month, 0).getDate();
        var days = [];
        for (var i = firstDay - 1; i >= 0; i--) {
            days.push({
                "dayNumber": prevTotalDays - i,
                "isCurrentMonth": false,
                "isToday": false
            });
        }
        for (var j = 1; j <= totalDays; j++) {
            var today = new Date();
            var matchToday = (j === today.getDate() && month === today.getMonth() && year === today.getFullYear());
            days.push({
                "dayNumber": j,
                "isCurrentMonth": true,
                "isToday": matchToday
            });
        }
        var nextDaysNeeded = 42 - days.length;
        for (var k = 1; k <= nextDaysNeeded; k++) {
            days.push({
                "dayNumber": k,
                "isCurrentMonth": false,
                "isToday": false
            });
        }
        calendarDays = days;
    }

    function refreshWifi() {
        if (externalWifiScanner.running)
            return ;

        externalWifiScanner.running = true;
    }

    function attemptConnect(ssid, password) {
        connectError = "";
        connecting = true;
        connectProcess.command = ["nmcli", "device", "wifi", "connect", ssid, "password", password];
        connectProcess.running = true;
    }

    function requestConnect(ssid, known) {
        if (known) {
            var reconnectCmd = Qt.createQmlObject('import Quickshell.Io; Process {}', rootPanel);
            reconnectCmd.command = ["nmcli", "connection", "up", ssid];
            reconnectCmd.running = true;
        } else {
            pendingSsid = ssid;
            connectError = "";
            passwordField.text = "";
        }
    }

    width: 300
    height: 230
    Component.onCompleted: {
        refreshWifi();
        generateCalendar();
        rootPanel.animateOpen = true;
    }
    opacity: 0
    transform: [
        Scale {
            id: panelScaleTransform

            origin.x: rootPanel.width / 2
            origin.y: 0
            xScale: 1
            yScale: 1
        },
        Translate {
            id: panelTranslateTransform

            y: -rootPanel.height - 20
        }
    ]
    states: [
        State {
            name: "open"
            when: rootPanel.animateOpen

            PropertyChanges {
                target: rootPanel
                opacity: 1
            }

            PropertyChanges {
                target: panelScaleTransform
                xScale: 1
                yScale: 1
            }

            PropertyChanges {
                target: panelTranslateTransform
                y: 0
            }

        },
        State {
            name: "closed"
            when: !rootPanel.animateOpen

            PropertyChanges {
                target: rootPanel
                opacity: 0
            }

            PropertyChanges {
                target: panelScaleTransform
                xScale: 1
                yScale: 1
            }

            PropertyChanges {
                target: panelTranslateTransform
                y: -rootPanel.height - 20
            }

        }
    ]
    transitions: [
        Transition {
            from: "closed"
            to: "open"

            ParallelAnimation {
                NumberAnimation {
                    target: panelTranslateTransform
                    property: "y"
                    duration: 550
                    easing.type: Easing.OutQuart
                }

                NumberAnimation {
                    target: rootPanel
                    property: "opacity"
                    duration: 350
                    easing.type: Easing.OutCubic
                }

            }

        },
        Transition {
            from: "open"
            to: "closed"

            ParallelAnimation {
                NumberAnimation {
                    target: panelTranslateTransform
                    property: "y"
                    duration: rootPanel.closeDuration
                    easing.type: Easing.InQuart
                }

                NumberAnimation {
                    target: rootPanel
                    property: "opacity"
                    duration: rootPanel.closeDuration
                    easing.type: Easing.InCubic
                }

            }

        }
    ]

    Timer {
        id: closeTimer

        interval: rootPanel.closeDuration
        repeat: false
        onTriggered: rootPanel.closed()
    }
    // ANIMATION END

    // Background Panel Mask
    Item {
        id: backgroundShape

        anchors.fill: parent
        z: -1

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Theme.bg0
            bottomLeftRadius: 12
            bottomRightRadius: 12
        }

        Rectangle {
            color: Theme.bg0
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.max(0, parent.height - 12)
        }

        Rectangle {
            color: Theme.bg0
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: Math.max(0, parent.width - 12)
        }

    }

    RoundedCorner {
        anchors.top: rootPanel.top
        anchors.right: rootPanel.left
        color: Theme.bg0
        size: 12
        corner: 2
        z: 10
    }

    RoundedCorner {
        id: bottomRightFillet

        anchors.top: rootPanel.bottom
        anchors.right: rootPanel.right
        color: Theme.bg0
        size: 12
        corner: 2 // Adjust corner number (0, 1, 2, or 3) to orient the curve correctly
        z: 10
    }

    // Battery Worker Daemon
    Process {
        id: batteryDaemonReader

        command: ["bash", "-c", "upower -i $(upower -e | grep 'battery') | grep -E 'state|percentage|energy-rate|time to empty|time to full'"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.split('\n');
                var percent = 100;
                var state = "discharging";
                var rate = 0;
                var timeStr = "";
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.indexOf("percentage:") === 0)
                        percent = parseInt(line.replace("percentage:", "").replace("%", "").trim());
                    else if (line.indexOf("state:") === 0)
                        state = line.replace("state:", "").trim();
                    else if (line.indexOf("energy-rate:") === 0)
                        rate = parseFloat(line.replace("energy-rate:", "").replace("W", "").trim());
                    else if (line.indexOf("time to empty:") === 0)
                        timeStr = line.replace("time to empty:", "").trim() + " until empty";
                    else if (line.indexOf("time to full:") === 0)
                        timeStr = line.replace("time to full:", "").trim() + " until full";
                }
                rootPanel.batteryPercentage = percent;
                rootPanel.batteryState = state;
                rootPanel.batteryEnergyRate = rate;
                rootPanel.batteryTimeRemaining = timeStr !== "" ? timeStr : (state === "fully-charged" ? "fully charged" : "calculating...");
            }
        }

    }

    Timer {
        id: batteryUpdateTimer

        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            batteryDaemonReader.running = true;
        }
    }

    Process {
        id: externalWifiScanner

        command: ["bash", "/home/nathan/.config/quickshell/modules/controlcenter/wifi_scanner.sh"]
        onRunningChanged: {
            rootPanel.isScanning = running;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                var rawText = text;
                if (!rawText || rawText.trim() === "")
                    return ;

                if (rawText.includes("END_JSON"))
                    rawText = rawText.replace("END_JSON", "");

                try {
                    var payload = JSON.parse(rawText.trim());
                    rootPanel.activeWifi = payload.active || "Disconnected";
                    var networkArray = payload.networks || [];
                    networkArray.sort(function(a, b) {
                        if ((a.ssid === rootPanel.activeWifi) !== (b.ssid === rootPanel.activeWifi))
                            return (a.ssid === rootPanel.activeWifi) ? -1 : 1;

                        return (b.known ? 1 : 0) - (a.known ? 1 : 0);
                    });
                    rootPanel.wifiNetworks = networkArray;
                } catch (err) {
                    console.log("JSON Network Sync Failure: ", err);
                }
            }
        }

    }

    Process {
        id: connectProcess

        property string outputBuf: ""
        property string errorBuf: ""

        onRunningChanged: {
            if (running) {
                outputBuf = "";
                errorBuf = "";
            }
        }

        stdout: StdioCollector {
            onStreamFinished: {
                connectProcess.outputBuf = text;
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                connectProcess.errorBuf = text;
                rootPanel.connecting = false;
                var combined = (connectProcess.outputBuf + " " + text).toLowerCase();
                if (combined.indexOf("error") !== -1 || combined.indexOf("secrets were required") !== -1 || combined.indexOf("fail") !== -1) {
                    rootPanel.connectError = "Incorrect password or connection failed";
                } else {
                    rootPanel.connectError = "";
                    rootPanel.pendingSsid = "";
                    passwordField.text = "";
                    refreshWifi();
                }
            }
        }

    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: refreshWifi()
    }

    // Updated Layout: Clickable Dot Pagination Row with Dynamic Width Scaling Accent
    Row {
        id: dotIndicatorHeaderRow

        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6
        z: 10

        Repeater {
            model: viewStack.count

            delegate: Rectangle {
                width: index === viewStack.currentIndex ? 16 : 6
                height: 6
                radius: 3
                color: index === viewStack.currentIndex ? Theme.rose : Theme.grey1
                opacity: index === viewStack.currentIndex ? 1 : 0.5

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    onClicked: {
                        viewStack.currentIndex = index;
                    }
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

    WheelHandler {
        id: globalWheelController

        parent: rootPanel
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            if (event.angleDelta.y < 0 || event.angleDelta.x < 0) {
                if (viewStack.currentIndex < viewStack.count - 1)
                    viewStack.currentIndex++;

            } else {
                if (viewStack.currentIndex > 0)
                    viewStack.currentIndex--;

            }
        }
    }

    Row {
        id: headerNavRow

        anchors.top: parent.top
        anchors.topMargin: 24
        anchors.left: parent.left
        anchors.leftMargin: rootPanel.headerMargin
        spacing: 8
        z: 20

        Text {
            text: "Calendar"
            color: viewStack.currentIndex === 0 ? Theme.rose : "#6c7086"
            font.bold: true
            font.family: "Rubik"
            font.pixelSize: rootPanel.titleFontSize

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointerCursor
                onClicked: {
                    viewStack.currentIndex = 0;
                }
            }

        }

        Text {
            text: "Bluetooth"
            color: viewStack.currentIndex === 1 ? Theme.rose : "#6c7086"
            font.bold: true
            font.family: "Rubik"
            font.pixelSize: rootPanel.titleFontSize

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointerCursor
                onClicked: {
                    viewStack.currentIndex = 1;
                }
            }

        }

        Text {
            text: "Sound"
            color: viewStack.currentIndex === 2 ? Theme.rose : "#6c7086"
            font.bold: true
            font.family: "Rubik"
            font.pixelSize: rootPanel.titleFontSize

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointerCursor
                onClicked: {
                    viewStack.currentIndex = 2;
                }
            }

        }

        Text {
            text: "Networks"
            color: viewStack.currentIndex === 3 ? Theme.rose : "#6c7086"
            font.bold: true
            font.family: "Rubik"
            font.pixelSize: rootPanel.titleFontSize

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointerCursor
                onClicked: {
                    viewStack.currentIndex = 3;
                }
            }

        }

        Text {
            text: "Battery"
            color: viewStack.currentIndex === 4 ? Theme.rose : "#6c7086"
            font.bold: true
            font.family: "Rubik"
            font.pixelSize: rootPanel.titleFontSize

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointerCursor
                onClicked: {
                    viewStack.currentIndex = 4;
                }
            }

        }

    }

    SwipeView {
        id: viewStack

        anchors.fill: parent
        anchors.topMargin: 52
        clip: true
        z: 0
        interactive: true

        // PAGE 1: CALENDAR
        Item {
            id: calendarPage

            Item {
                id: calendarContainer

                anchors.fill: parent
                anchors.leftMargin: rootPanel.headerMargin
                anchors.rightMargin: rootPanel.headerMargin
                anchors.bottomMargin: 10

                Text {
                    id: monthYearTitle

                    text: rootPanel.monthNames[rootPanel.currentDate.getMonth()] + " " + rootPanel.currentDate.getFullYear()
                    color: Theme.rose
                    font.family: "Rubik"
                    font.bold: true
                    font.pixelSize: rootPanel.rowFontSize
                }

                Row {
                    id: daysOfWeekHeader

                    anchors.top: monthYearTitle.bottom
                    anchors.topMargin: 6
                    anchors.left: parent.left
                    anchors.right: parent.right

                    Repeater {
                        model: ["S", "M", "T", "W", "T", "F", "S"]

                        delegate: Text {
                            width: calendarContainer.width / 7
                            text: modelData
                            color: "#6c7086"
                            font.family: "Rubik"
                            font.pixelSize: rootPanel.rowFontSize - 1
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                    }

                }

                Grid {
                    id: dateGrid

                    anchors.top: daysOfWeekHeader.bottom
                    anchors.topMargin: 4
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    columns: 7
                    rows: 6

                    Repeater {
                        model: rootPanel.calendarDays

                        delegate: Item {
                            width: calendarContainer.width / 7
                            height: Math.floor(dateGrid.height / 6)

                            Rectangle {
                                anchors.centerIn: parent
                                width: Math.min(parent.width, parent.height) - 4
                                height: width
                                radius: width / 2
                                color: modelData.isToday ? Theme.rose : "transparent"
                                visible: modelData.isToday
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.dayNumber
                                font.family: "Rubik"
                                font.pixelSize: rootPanel.rowFontSize - 1
                                font.bold: modelData.isToday
                                color: modelData.isToday ? Theme.bg0 : (modelData.isCurrentMonth ? Theme.text : Theme.grey0)
                            }

                        }

                    }

                }

            }

        }

        // PAGE 2: BLUETOOTH MENU
        Item {
            id: bluetoothPage

            Item {
                id: bluetoothContainer

                anchors.fill: parent
                anchors.leftMargin: rootPanel.headerMargin
                anchors.rightMargin: rootPanel.headerMargin
                anchors.bottomMargin: 14

                Text {
                    text: "scan"
                    color: Theme.rose
                    font.family: "Rubik"
                    font.pixelSize: rootPanel.rowFontSize
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.rightMargin: 65
                }

                Text {
                    text: "refresh"
                    color: Theme.rose
                    font.family: "Rubik"
                    font.pixelSize: rootPanel.rowFontSize
                    anchors.top: parent.top
                    anchors.right: parent.right
                }

                ListView {
                    id: bluetoothListView

                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: rootPanel.headerMargin + 4
                    spacing: rootPanel.rowSpacing
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: [{
                        "name": "M720 Triathlon",
                        "mac": "00:11:22:33:44:55"
                    }, {
                        "name": "SK71PR0-BT2",
                        "mac": "FC:AF:73:63:19:CA"
                    }, {
                        "name": "Nathan's AirPods",
                        "mac": "70:8C:F2:55:54:0A"
                    }]

                    delegate: Rectangle {
                        width: bluetoothListView.width
                        height: rootPanel.rowHeight
                        color: Theme.bg1
                        radius: 6

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointerCursor
                            preventStealing: true
                            onClicked: {
                                var btConnectCmd = Qt.createQmlObject('import Quickshell.Io; Process {}', rootPanel);
                                btConnectCmd.command = ["bluetoothctl", "connect", modelData.mac];
                                btConnectCmd.running = true;
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: modelData.name
                                color: Theme.text
                                font.family: "Rubik"
                                font.pixelSize: rootPanel.rowFontSize
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                        }

                    }

                }

            }

        }

        // PAGE 3: SOUND SLIDERS
        Item {
            id: soundPage

            Item {
                id: soundContainer

                anchors.fill: parent
                anchors.leftMargin: 30
                anchors.rightMargin: 30
                anchors.bottomMargin: 10

                Row {
                    anchors.fill: parent
                    spacing: 50

                    Column {
                        width: (parent.width - 50) / 2
                        height: parent.height
                        spacing: 6

                        Rectangle {
                            id: volTrack

                            width: 24
                            height: parent.height - 24
                            radius: 12
                            color: Theme.bg1
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                width: parent.width
                                height: parent.height * rootPanel.volumeLevel
                                radius: 12
                                color: Theme.text
                                anchors.bottom: parent.bottom
                            }

                            MouseArea {
                                function updateVol(mouseY) {
                                    var pct = 1 - (mouseY / height);
                                    var finalLevel = Math.max(0, Math.min(1, pct));
                                    rootPanel.volumeLevel = finalLevel;
                                    rootPanel.setSystemVolume(finalLevel);
                                }

                                anchors.fill: parent
                                preventStealing: true
                                onPressed: (mouse) => {
                                    return updateVol(mouse.y);
                                }
                                onPositionChanged: (mouse) => {
                                    return updateVol(mouse.y);
                                }
                            }

                        }

                        Text {
                            text: "vol"
                            color: Theme.text
                            font.family: "Rubik"
                            font.pixelSize: rootPanel.rowFontSize
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                    }

                    Column {
                        width: (parent.width - 50) / 2
                        height: parent.height
                        spacing: 6

                        Rectangle {
                            id: micTrack

                            width: 24
                            height: parent.height - 24
                            radius: 12
                            color: Theme.bg1
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                width: parent.width
                                height: parent.height * rootPanel.micLevel
                                radius: 12
                                color: Theme.rose
                                anchors.bottom: parent.bottom
                            }

                            MouseArea {
                                function updateMic(mouseY) {
                                    var pct = 1 - (mouseY / height);
                                    var finalLevel = Math.max(0, Math.min(1, pct));
                                    rootPanel.micLevel = finalLevel;
                                    rootPanel.setSystemMicrophone(finalLevel);
                                }

                                anchors.fill: parent
                                preventStealing: true
                                onPressed: (mouse) => {
                                    return updateMic(mouse.y);
                                }
                                onPositionChanged: (mouse) => {
                                    return updateMic(mouse.y);
                                }
                            }

                        }

                        Text {
                            text: "mic"
                            color: Theme.text
                            font.family: "Rubik"
                            font.pixelSize: rootPanel.rowFontSize
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                    }

                }

            }

        }

        // PAGE 4: WI-FI NETWORKS
        Item {
            id: wifiPage

            Item {
                id: container

                anchors.fill: parent
                anchors.leftMargin: rootPanel.headerMargin
                anchors.rightMargin: rootPanel.headerMargin
                anchors.bottomMargin: 14

                Text {
                    text: rootPanel.isScanning ? "scanning..." : "Refresh"
                    color: rootPanel.isScanning ? "#6c7086" : Theme.rose
                    font.family: "Rubik"
                    font.pixelSize: rootPanel.rowFontSize
                    anchors.top: parent.top
                    anchors.right: parent.right

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointerCursor
                        enabled: !rootPanel.isScanning
                        onClicked: {
                            refreshWifi();
                        }
                    }

                }

                Text {
                    anchors.centerIn: parent
                    text: rootPanel.isScanning ? "Scanning for networks..." : "No networks found"
                    color: "#6c7086"
                    font.family: "Rubik"
                    font.pixelSize: rootPanel.rowFontSize
                    visible: networkListView.count === 0 && rootPanel.pendingSsid === ""
                }

                ListView {
                    id: networkListView

                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: rootPanel.headerMargin + 4
                    spacing: rootPanel.rowSpacing
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: rootPanel.wifiNetworks
                    visible: rootPanel.pendingSsid === ""

                    delegate: Rectangle {
                        width: networkListView.width
                        height: rootPanel.rowHeight
                        color: modelData.ssid === rootPanel.activeWifi ? Theme.bg1 : Theme.bg2
                        radius: 6
                        border.color: modelData.ssid === rootPanel.activeWifi ? Theme.rose : "transparent"
                        border.width: 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointerCursor
                            preventStealing: true
                            onClicked: {
                                if (modelData.ssid !== rootPanel.activeWifi)
                                    requestConnect(modelData.ssid, modelData.known);

                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: modelData.ssid === "" ? "<Hidden Network>" : modelData.ssid
                                color: modelData.ssid === rootPanel.activeWifi ? Theme.rose : Theme.text
                                font.family: "Rubik"
                                font.pixelSize: rootPanel.rowFontSize
                                font.bold: modelData.ssid === rootPanel.activeWifi
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: modelData.ssid === rootPanel.activeWifi ? "󰖩" : (modelData.secure ? "󰖪" : "")
                                color: modelData.ssid === rootPanel.activeWifi ? Theme.rose : "#6c7086"
                                font.family: "Rubik"
                                font.pixelSize: rootPanel.rowFontSize + 2
                                Layout.alignment: Qt.AlignVCenter
                            }

                        }

                    }

                }

                // Password overlay window block inside container bounds
                ColumnLayout {
                    id: passwordPromptBox

                    anchors.fill: parent
                    anchors.topMargin: 10
                    visible: rootPanel.pendingSsid !== ""
                    spacing: 12

                    Text {
                        text: "Connect to: " + rootPanel.pendingSsid
                        color: Theme.text
                        font.family: "Rubik"
                        font.bold: true
                        font.pixelSize: rootPanel.rowFontSize
                    }

                    TextField {
                        id: passwordField

                        Layout.fillWidth: true
                        placeholderText: "Enter Wi-Fi Password..."
                        echoMode: TextInput.Password
                        color: Theme.text
                        placeholderTextColor: "#6c7086"
                        selectedTextColor: Theme.bg0
                        selectionColor: Theme.rose
                        font.family: "Rubik"
                        font.pixelSize: rootPanel.rowFontSize

                        background: Rectangle {
                            color: Theme.bg2
                            radius: 6
                            border.color: passwordField.activeFocus ? Theme.rose : "#44475a"
                            border.width: 1
                        }

                    }

                    Text {
                        text: rootPanel.connectError
                        color: Theme.rose
                        font.family: "Rubik"
                        font.pixelSize: rootPanel.rowFontSize - 1
                        visible: rootPanel.connectError !== ""
                        Layout.fillWidth: true
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        spacing: 10
                        Layout.alignment: Qt.AlignRight

                        Button {
                            text: "Cancel"
                            enabled: !rootPanel.connecting
                            onClicked: {
                                rootPanel.pendingSsid = "";
                                rootPanel.connectError = "";
                                passwordField.text = "";
                            }
                        }

                        Button {
                            text: rootPanel.connecting ? "Connecting..." : "Connect"
                            enabled: !rootPanel.connecting && passwordField.text.length >= 8
                            onClicked: {
                                attemptConnect(rootPanel.pendingSsid, passwordField.text);
                            }
                        }

                    }

                    Item {
                        Layout.fillHeight: true
                    }

                }

            }

        }

        // PAGE 5: BATTERY INFORMATION DIAGNOSTICS
        Item {
            id: batteryPage

            Item {
                id: batteryContainer

                anchors.fill: parent
                anchors.leftMargin: rootPanel.headerMargin
                anchors.rightMargin: rootPanel.headerMargin
                anchors.bottomMargin: 10

                RowLayout {
                    id: mainBatteryLayout

                    anchors.fill: parent
                    spacing: 20

                    // Left Side Column: Large Level Accent Box Graphic Indicator
                    ColumnLayout {
                        spacing: 6
                        Layout.preferredWidth: 80
                        Layout.fillHeight: true

                        Rectangle {
                            id: batteryBodyShell

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Theme.bg2
                            radius: 8
                            border.color: "#44475a"
                            border.width: 1

                            // Core internal fluid fill line
                            Rectangle {
                                id: batteryLiquidBar

                                width: parent.width - 4
                                height: Math.max(4, (parent.height - 4) * (rootPanel.batteryPercentage / 100))
                                radius: 6
                                color: rootPanel.batteryState.indexOf("charging") !== -1 ? Theme.foam : (rootPanel.batteryPercentage <= 20 ? Theme.rose : Theme.rose)
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            // Big Text Overlay inside physical representation
                            Text {
                                text: rootPanel.batteryPercentage + "%"
                                font.family: "Rubik"
                                font.bold: true
                                font.pixelSize: rootPanel.rowFontSize + 2
                                color: Theme.text
                                anchors.centerIn: parent
                                z: 5
                            }

                        }

                    }

                    // Right Side Dynamic Status Fields Diagnostics Data Column
                    ColumnLayout {
                        spacing: 4
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                            text: "Power Status"
                            color: "#6c7086"
                            font.family: "Rubik"
                            font.bold: true
                            font.pixelSize: rootPanel.rowFontSize - 1
                        }

                        Text {
                            text: rootPanel.batteryState.toUpperCase().replace("-", " ")
                            color: Theme.text
                            font.family: "Rubik"
                            font.bold: true
                            font.pixelSize: rootPanel.rowFontSize + 1
                        }

                        Item {
                            Layout.preferredHeight: 4
                        }

                        Text {
                            text: "Time Metrics"
                            color: "#6c7086"
                            font.family: "Rubik"
                            font.bold: true
                            font.pixelSize: rootPanel.rowFontSize - 1
                        }

                        Text {
                            text: rootPanel.batteryTimeRemaining
                            color: Theme.text
                            font.family: "Rubik"
                            font.pixelSize: rootPanel.rowFontSize
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }

                        Item {
                            Layout.preferredHeight: 4
                        }

                        Text {
                            text: "Usage Drain Rate"
                            color: "#6c7086"
                            font.family: "Rubik"
                            font.bold: true
                            font.pixelSize: rootPanel.rowFontSize - 1
                        }

                        Text {
                            text: rootPanel.batteryEnergyRate.toFixed(2) + " Watts"
                            color: Theme.text
                            font.family: "Rubik"
                            font.pixelSize: rootPanel.rowFontSize
                        }

                    }

                }

            }

        }

    }

}
