import "../theme"
import "../top"
import "../weather" as WeatherModule
import "../weather/weatherService.js" as WeatherService
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io

Item {
    id: leftMenuRoot

    // Expose leftSwipeView for topbar.qml
    property alias currentTabIndex: leftSwipeView.currentIndex

    // Dynamic track properties
    property string currentTitle: "Not Playing"
    property string currentArtist: "Unknown Artist"
    property string defaultCover: Qt.resolvedUrl("../pictures/Shiba.png")
    property string currentCover: leftMenuRoot.defaultCover
    property bool isPlayingTrack: false

    // Real audio levels from cava (raw ascii output, one value per bar)
    property var cavaLevels: []

    // ==========================================================
    // >>> ANIMATION BLOCK <<<
    // ==========================================================
    property bool animateOpen: false
    readonly property int closeDuration: 550

    // ==========================================================
    // >>> WEATHER DATA (populated by weatherService.js) <<<
    // ==========================================================
    property string locationName: WeatherService.LOCATION_NAME || "Weather"
    property string currentTemp: "--"
    property string currentCondition: "Unknown"
    property int currentConditionCode: 0
    property string currentHumidity: "--%"
    property string currentFeelsLike: "--"
    property string currentWind: "-- km/h"
    property string sunriseTime: "--:--"
    property string sunsetTime: "--:--"
    property var dailyData: []

    // ==========================================================
    // >>> SCHEDULE DATA (populated from a local .json/.jsonc file) <<<
    // ==========================================================
    // Expected file shape:
    // {
    //   "monday": [ { "time": "8:00 AM", "title": "Gym" }, { "time": "2:00 PM - 3:00 PM", "title": "Work" } ],
    //   "tuesday": [ ... ], "wednesday": [ ... ], "thursday": [ ... ],
    //   "friday": [ ... ], "saturday": [ ... ], "sunday": [ ... ]
    // }
    // "time" supports either a single time ("9:00 AM") or a range
    // ("9:00 AM - 10:30 AM", also accepts "to" instead of "-").
    property string schedulePath: Quickshell.env("HOME") + "/.config/quickshell/schedule.jsonc"
    property var scheduleData: ({})
    property var todayEvents: {
        var key = todayKey();
        return (scheduleData && scheduleData[key]) ? scheduleData[key] : [];
    }

    // ==========================================================
    // >>> HOMEWORK TRACKER DATA (populated from a local .json file) <<<
    // ==========================================================
    // Expected file shape:
    // {
    //   "classes": [ { "id": "abc123", "name": "Chemistry", "color": "#eb6f92" }, ... ],
    //   "assignments": [
    //     { "id": "xyz789", "title": "Lab report", "classId": "abc123", "dueDate": "2026-09-02", "done": false },
    //     ...
    //   ]
    // }
    property string homeworkPath: Quickshell.env("HOME") + "/.config/quickshell/homework.jsonc"
    property var homeworkClasses: []
    property var homeworkAssignments: []

    property bool homeworkAddFormVisible: false
    property bool homeworkManageClassesVisible: false
    property string hwFormTitle: ""
    property string hwFormClassId: ""
    property string hwFormDueDate: ""
    property int hwFormDueYear: new Date().getFullYear()
    property int hwFormDueMonth: new Date().getMonth() + 1
    property int hwFormDueDay: new Date().getDate()
    property string hwNewClassName: ""
    property string hwNewClassColor: ""

    readonly property var homeworkColorPalette: [Theme.love, Theme.gold, Theme.rose, Theme.pine, Theme.foam, Theme.iris]

    signal closed()

    function requestClose() {
        animateOpen = false;
        closeTimer.restart();
    }

    function weatherIcon(code) {
        return WeatherService.getWeatherIcon(code);
    }

    function weatherConditionText(code) {
        return WeatherService.getConditionText(code);
    }

    function getDayName(dateStr) {
        if (!dateStr)
            return "";

        var parts = dateStr.split('-');
        if (parts.length !== 3)
            return "";

        var year = parseInt(parts[0], 10);
        var month = parseInt(parts[1], 10) - 1;
        var day = parseInt(parts[2], 10);
        var date = new Date(year, month, day);
        var today = new Date();
        date.setHours(0, 0, 0, 0);
        today.setHours(0, 0, 0, 0);
        if (date.getTime() === today.getTime())
            return 'Today';

        var names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        return names[date.getDay()];
    }

    function formatShortDate(dateStr) {
        if (!dateStr)
            return "";

        var parts = dateStr.split('-');
        if (parts.length !== 3)
            return "";

        var date = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
        return date.toLocaleDateString('en-US', {
            "month": 'short',
            "day": 'numeric'
        });
    }

    function formatTime(isoStr) {
        if (!isoStr)
            return "--:--";

        try {
            var date = new Date(isoStr);
            return date.toLocaleTimeString('en-US', {
                "hour": 'numeric',
                "minute": '2-digit',
                "hour12": true
            });
        } catch (e) {
            return "--:--";
        }
    }

    // Called by weatherService.js once the API responds
    function handleWeatherData(data) {
        try {
            var cur = data.current;
            if (cur) {
                if (cur.temperature_2m !== undefined)
                    leftMenuRoot.currentTemp = Math.round(cur.temperature_2m) + "°C";
                if (cur.weather_code !== undefined) {
                    leftMenuRoot.currentConditionCode = cur.weather_code;
                    leftMenuRoot.currentCondition = weatherConditionText(cur.weather_code);
                }
                leftMenuRoot.currentHumidity = (cur.relative_humidity_2m !== undefined) ? cur.relative_humidity_2m + "%" : "--%";
                leftMenuRoot.currentFeelsLike = (cur.apparent_temperature !== undefined) ? Math.round(cur.apparent_temperature) + "°C" : "--";
                leftMenuRoot.currentWind = (cur.wind_speed_10m !== undefined) ? Math.round(cur.wind_speed_10m) + " km/h" : "-- km/h";
            }

            var d = data.daily;
            if (d) {
                if (d.sunrise && d.sunrise.length > 0)
                    leftMenuRoot.sunriseTime = formatTime(d.sunrise[0]);
                if (d.sunset && d.sunset.length > 0)
                    leftMenuRoot.sunsetTime = formatTime(d.sunset[0]);

                if (d.time && d.temperature_2m_max) {
                    var list = [];
                    var todayBaseline = new Date();
                    todayBaseline.setHours(0, 0, 0, 0);
                    for (var i = 0; i < d.time.length; i++) {
                        var parts = d.time[i].split('-');
                        var checkDate = new Date(parseInt(parts[0], 10), parseInt(parts[1], 10) - 1, parseInt(parts[2], 10));
                        checkDate.setHours(0, 0, 0, 0);
                        if (checkDate.getTime() >= todayBaseline.getTime()) {
                            list.push({
                                "dayName": getDayName(d.time[i]),
                                "formattedDate": formatShortDate(d.time[i]),
                                "icon": weatherIcon(d.weather_code[i]),
                                "tempRange": Math.round(d.temperature_2m_min[i]) + "° / " + Math.round(d.temperature_2m_max[i]) + "°"
                            });
                        }
                    }
                    leftMenuRoot.dailyData = list.slice(0, 7);
                }
            }
        } catch (e) {
            console.log("Weather handling error: " + e);
        }
    }

    // ---- Schedule helpers ----

    function todayKey() {
        var names = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"];
        return names[new Date().getDay()];
    }

    function todayLabel() {
        var names = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
        return names[new Date().getDay()];
    }

    // Strips // line comments and /* block comments */ so plain JSON.parse can
    // handle a .jsonc file. Simple pass - doesn't understand // inside strings,
    // so avoid literal "//" inside your event titles.
    function stripJsonComments(str) {
        return str.replace(/\/\*[\s\S]*?\*\//g, '').replace(/(^|[^:])\/\/.*$/gm, '$1');
    }

    function parseSchedule(text) {
        if (!text || text.trim() === "")
            return;
        try {
            var cleaned = stripJsonComments(text);
            leftMenuRoot.scheduleData = JSON.parse(cleaned);
        } catch (e) {
            console.log("Schedule parse error: " + e);
        }
    }

    // ---- Homework tracker helpers ----

    function generateId() {
        return Date.now().toString(36) + Math.random().toString(36).substr(2, 5);
    }

    function daysInMonth(year, month) {
        return new Date(year, month, 0).getDate();
    }

    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }

    // Recomputes hwFormDueDate ("YYYY-MM-DD") from the year/month/day wheel
    // state, clamping the day if switching to a shorter month (e.g. Feb).
    function updateHwFormDueDateFromParts() {
        var maxDay = leftMenuRoot.daysInMonth(leftMenuRoot.hwFormDueYear, leftMenuRoot.hwFormDueMonth);
        if (leftMenuRoot.hwFormDueDay > maxDay)
            leftMenuRoot.hwFormDueDay = maxDay;
        leftMenuRoot.hwFormDueDate = leftMenuRoot.hwFormDueYear + "-" + leftMenuRoot.pad2(leftMenuRoot.hwFormDueMonth) + "-" + leftMenuRoot.pad2(leftMenuRoot.hwFormDueDay);
    }

    // Snaps all three wheels back to today's date. Tumbler.currentIndex
    // breaks its binding the moment the user flicks it (same reason
    // TextField.text needs onTextChanged instead of a plain binding), so
    // resetting hwFormDueYear/Month/Day alone won't move the wheels back -
    // this also pushes the values into the Tumblers directly via their ids.
    function resetHwDueDateWheels() {
        var today = new Date();
        leftMenuRoot.hwFormDueYear = today.getFullYear();
        leftMenuRoot.hwFormDueMonth = today.getMonth() + 1;
        leftMenuRoot.hwFormDueDay = today.getDate();
        leftMenuRoot.updateHwFormDueDateFromParts();
        if (typeof hwMonthTumbler !== "undefined") {
            hwMonthTumbler.currentIndex = leftMenuRoot.hwFormDueMonth - 1;
            hwDayTumbler.currentIndex = leftMenuRoot.hwFormDueDay - 1;
            hwYearTumbler.currentIndex = 0;
        }
    }

    function parseHomeworkData(text) {
        if (!text || text.trim() === "")
            return;
        try {
            var cleaned = stripJsonComments(text);
            var data = JSON.parse(cleaned);
            leftMenuRoot.homeworkClasses = data.classes || [];
            leftMenuRoot.homeworkAssignments = data.assignments || [];
        } catch (e) {
            console.log("Homework parse error: " + e);
        }
    }

    function saveHomeworkData() {
        var payload = {
            "classes": leftMenuRoot.homeworkClasses,
            "assignments": leftMenuRoot.homeworkAssignments
        };
        homeworkFileView.setText(JSON.stringify(payload, null, 2));
    }

    function homeworkClassById(id) {
        if (!id)
            return null;
        for (var i = 0; i < leftMenuRoot.homeworkClasses.length; i++) {
            if (leftMenuRoot.homeworkClasses[i].id === id)
                return leftMenuRoot.homeworkClasses[i];
        }
        return null;
    }

    function homeworkClassColor(id) {
        var cls = leftMenuRoot.homeworkClassById(id);
        return cls ? cls.color : Theme.subText;
    }

    function homeworkClassName(id) {
        var cls = leftMenuRoot.homeworkClassById(id);
        return cls ? cls.name : "No class";
    }

    function addHomeworkClass(name, color) {
        if (!name || name.trim() === "")
            return;
        var newClass = {
            "id": leftMenuRoot.generateId(),
            "name": name.trim(),
            "color": color
        };
        leftMenuRoot.homeworkClasses = leftMenuRoot.homeworkClasses.concat([newClass]);
        leftMenuRoot.saveHomeworkData();
    }

    function deleteHomeworkClass(id) {
        leftMenuRoot.homeworkClasses = leftMenuRoot.homeworkClasses.filter(function (c) {
            return c.id !== id;
        });
        // Orphaned assignments fall back to "No class" instead of disappearing
        leftMenuRoot.homeworkAssignments = leftMenuRoot.homeworkAssignments.map(function (a) {
            if (a.classId !== id)
                return a;
            var copy = Object.assign({}, a);
            copy.classId = "";
            return copy;
        });
        leftMenuRoot.saveHomeworkData();
    }

    function addHomeworkAssignment(title, classId, dueDate) {
        if (!title || title.trim() === "")
            return;
        var newItem = {
            "id": leftMenuRoot.generateId(),
            "title": title.trim(),
            "classId": classId || "",
            "dueDate": (dueDate || "").trim(),
            "done": false
        };
        leftMenuRoot.homeworkAssignments = leftMenuRoot.homeworkAssignments.concat([newItem]);
        leftMenuRoot.saveHomeworkData();
    }

    function toggleHomeworkDone(id) {
        leftMenuRoot.homeworkAssignments = leftMenuRoot.homeworkAssignments.map(function (a) {
            if (a.id !== id)
                return a;
            var copy = Object.assign({}, a);
            copy.done = !copy.done;
            return copy;
        });
        leftMenuRoot.saveHomeworkData();
    }

    function deleteHomeworkAssignment(id) {
        leftMenuRoot.homeworkAssignments = leftMenuRoot.homeworkAssignments.filter(function (a) {
            return a.id !== id;
        });
        leftMenuRoot.saveHomeworkData();
    }

    // Expects "YYYY-MM-DD"; returns a local-midnight Date, or null if unparseable/empty.
    function parseDueDate(dateStr) {
        if (!dateStr)
            return null;
        var m = dateStr.trim().match(/^(\d{4})-(\d{2})-(\d{2})$/);
        if (!m)
            return null;
        var d = new Date(parseInt(m[1], 10), parseInt(m[2], 10) - 1, parseInt(m[3], 10));
        d.setHours(0, 0, 0, 0);
        return d;
    }

    // Whole-day difference between today and the due date; null if unparseable.
    function daysUntilDue(dateStr) {
        var d = leftMenuRoot.parseDueDate(dateStr);
        if (!d)
            return null;
        var today = new Date();
        today.setHours(0, 0, 0, 0);
        return Math.round((d.getTime() - today.getTime()) / 86400000);
    }

    function dueDateLabel(dateStr) {
        var days = leftMenuRoot.daysUntilDue(dateStr);
        if (days === null)
            return dateStr && dateStr.trim() !== "" ? dateStr : "No due date";
        if (days < 0)
            return "Overdue " + Math.abs(days) + "d";
        if (days === 0)
            return "Due today";
        if (days === 1)
            return "Due tomorrow";
        return "Due in " + days + "d";
    }

    // Incomplete assignments first (soonest due date first, undated ones last
    // within that group), then completed assignments at the bottom.
    property var sortedHomeworkAssignments: {
        var items = leftMenuRoot.homeworkAssignments.slice();
        items.sort(function (a, b) {
            if (a.done !== b.done)
                return a.done ? 1 : -1;
            var da = leftMenuRoot.parseDueDate(a.dueDate);
            var db = leftMenuRoot.parseDueDate(b.dueDate);
            if (da === null && db === null)
                return 0;
            if (da === null)
                return 1;
            if (db === null)
                return -1;
            return da.getTime() - db.getTime();
        });
        return items;
    }

    // Splits the sorted list into 3 "newspaper" columns: column 1 fills
    // top-to-bottom first, then column 2, then column 3 with the remainder.
    function homeworkColumnItems(colIndex) {
        var items = leftMenuRoot.sortedHomeworkAssignments;
        var n = items.length;
        var perCol = Math.ceil(n / 3);
        if (perCol === 0)
            return [];
        var start = colIndex * perCol;
        if (start >= n)
            return [];
        return items.slice(start, Math.min(start + perCol, n));
    }

    property var homeworkColumn1: leftMenuRoot.homeworkColumnItems(0)
    property var homeworkColumn2: leftMenuRoot.homeworkColumnItems(1)
    property var homeworkColumn3: leftMenuRoot.homeworkColumnItems(2)

    // ---- "Next event" tracking ----
    // Ticks once a minute and figures out which of today's events is the
    // next upcoming (or currently in-progress) one, so the schedule panel
    // can highlight it and auto-scroll it to the top (while still allowing
    // the user to scroll up manually to see earlier events).

    property date nowTick: new Date()

    Timer {
        interval: 60000 // recheck every minute
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: leftMenuRoot.nowTick = new Date()
    }

    // Parses "8:00 AM" / "18:00" / "6:00 PM" style strings into minutes-since-midnight.
    // inheritAmPm ("AM"/"PM") is used when a range's start half omits AM/PM,
    // e.g. the "9:00" in "9:00 - 10:30 AM" borrows "PM"/"AM" from the end.
    // Returns -1 if it can't parse the string.
    function parseTimeToMinutes(timeStr, inheritAmPm) {
        if (!timeStr)
            return -1;
        var m = timeStr.trim().match(/^(\d{1,2}):(\d{2})\s*([AaPp][Mm])?$/);
        if (!m)
            return -1;
        var hours = parseInt(m[1], 10);
        var minutes = parseInt(m[2], 10);
        var ampm = m[3] ? m[3].toUpperCase() : (inheritAmPm || null);
        if (ampm === "PM" && hours !== 12)
            hours += 12;
        if (ampm === "AM" && hours === 12)
            hours = 0;
        return hours * 60 + minutes;
    }

    // Parses a schedule entry's "time" field, which can be either a single
    // time ("9:00 AM") or a range ("9:00 AM - 10:30 AM" / "9:00 to 10:30 AM").
    // Returns { start, end, isRange } in minutes-since-midnight; -1 for
    // either field means "couldn't parse".
    function parseEventRange(timeStr) {
        if (!timeStr)
            return {
                "start": -1,
                "end": -1,
                "isRange": false
            };

        var parts = timeStr.split(/\s*-\s*|\s+to\s+/i);
        if (parts.length === 2) {
            var endMatch = parts[1].trim().match(/([AaPp][Mm])\s*$/);
            var endAmPm = endMatch ? endMatch[1].toUpperCase() : null;
            var start = parseTimeToMinutes(parts[0], endAmPm);
            var end = parseTimeToMinutes(parts[1]);
            if (start !== -1 && end !== -1)
                return {
                    "start": start,
                    "end": end,
                    "isRange": true
                };
        }

        var single = parseTimeToMinutes(timeStr);
        return {
            "start": single,
            "end": single,
            "isRange": false
        };
    }

    // Index (within todayEvents) of the next upcoming/in-progress event;
    // -1 if none left today. Uses the event's END time so a range stays
    // highlighted for its whole duration, not just until it starts.
    property int nextEventIndex: {
        var events = leftMenuRoot.todayEvents;
        var nowMinutes = leftMenuRoot.nowTick.getHours() * 60 + leftMenuRoot.nowTick.getMinutes();
        if (!events)
            return -1;
        for (var i = 0; i < events.length; i++) {
            var range = parseEventRange(events[i].time);
            if (range.end === -1)
                continue;
            if (range.end >= nowMinutes)
                return i;
        }
        return -1;
    }

    onNextEventIndexChanged: {
        if (nextEventIndex >= 0 && scheduleListView)
            scheduleListView.positionViewAtIndex(nextEventIndex, ListView.Beginning);
    }

    //////////////////////////////////////////////////////////////////////////////
    // Adjust container dimensions to comfortably hold weather metrics & forecast
    //////////////////////////////////////////////////////////////////////////////
    property int weatherPanelHeight: 290
    property int playerPanelHeight: 282
    property int schedulePanelHeight: 300
    property int homeworkPanelHeight: 300
    // For width adjustments
    property int weatherPanelWidth: 550
    property int playerPanelWidth: 430
    property int schedulePanelWidth: 380
    property int homeworkPanelWidth: 540

    width: {
        if (leftSwipeView.currentIndex === 0) return weatherPanelWidth;
        if (leftSwipeView.currentIndex === 1) return playerPanelWidth;
        if (leftSwipeView.currentIndex === 2) return schedulePanelWidth;
        return homeworkPanelWidth;
    }
    height: {
        if (leftSwipeView.currentIndex === 0) return weatherPanelHeight;
        if (leftSwipeView.currentIndex === 1) return playerPanelHeight;
        if (leftSwipeView.currentIndex === 2) return schedulePanelHeight;
        return homeworkPanelHeight;
    }

    Behavior on height {
        SequentialAnimation {
            PauseAnimation { duration: 600 }
            NumberAnimation {
                duration: 600
                easing.type: Easing.OutExpo
            }
        }
    }

    Behavior on width {
        NumberAnimation {
            duration: 600
            easing.type: Easing.InOutCubic
        }
    }

    Component.onCompleted: {
        leftMenuRoot.animateOpen = true;
    }
    opacity: 0

    transform: [
        Scale {
            id: leftScaleTransform
            origin.x: (parent.width - width) / 2
            origin.y: 0
            xScale: 1
            yScale: 1
        },
        Translate {
            id: leftTranslateTransform
            y: -leftMenuRoot.height - 20
        }
    ]

    states: [
        State {
            name: "open"
            when: leftMenuRoot.animateOpen

            PropertyChanges {
                target: leftMenuRoot
                opacity: 1
            }
            PropertyChanges {
                target: leftScaleTransform
                xScale: 1
                yScale: 1
            }
            PropertyChanges {
                target: leftTranslateTransform
                y: 0
            }
        },
        State {
            name: "closed"
            when: !leftMenuRoot.animateOpen

            PropertyChanges {
                target: leftMenuRoot
                opacity: 0
            }
            PropertyChanges {
                target: leftScaleTransform
                xScale: 1
                yScale: 1
            }
            PropertyChanges {
                target: leftTranslateTransform
                y: -leftMenuRoot.height - 20
            }
        }
    ]

    transitions: [
        Transition {
            from: "closed"
            to: "open"

            ParallelAnimation {
                NumberAnimation {
                    target: leftTranslateTransform
                    property: "y"
                    duration: 550
                    easing.type: Easing.OutQuart
                }
                NumberAnimation {
                    target: leftMenuRoot
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
                    target: leftTranslateTransform
                    property: "y"
                    duration: leftMenuRoot.closeDuration
                    easing.type: Easing.InQuart
                }
                NumberAnimation {
                    target: leftMenuRoot
                    property: "opacity"
                    duration: leftMenuRoot.closeDuration
                    easing.type: Easing.InCubic
                }
            }
        }
    ]

    Timer {
        id: closeTimer
        interval: leftMenuRoot.closeDuration
        repeat: false
        onTriggered: leftMenuRoot.closed()
    }

    // ==========================================================
    // >>> STANDALONE MEDIA CONTROL PROCESSES <<<
    // ==========================================================
    Process {
        id: cmdPlayPause
        command: ["playerctl", "play-pause", "-p", "spotify"]
        running: false
    }

    Process {
        id: cmdNext
        command: ["playerctl", "next", "-p", "spotify"]
        running: false
    }

    Process {
        id: cmdPrev
        command: ["playerctl", "previous", "-p", "spotify"]
        running: false
    }

    // ==========================================================
    // >>> LIVE MEDIA TRACK METADATA ENGINE <<<
    // ==========================================================
    Process {
        id: mprisWatcher
        command: ["playerctl", "-p", "spotify", "metadata", "--format", "{{title}}|{{artist}}|{{status}}|{{mpris:artUrl}}", "-F"]
        running: true

        stdout: SplitParser {
            onRead: (text) => {
                if (!text || text.trim() === "")
                    return;

                var tokens = text.split('|');
                if (tokens.length >= 3) {
                    leftMenuRoot.currentTitle = tokens[0].trim() || "Title";
                    leftMenuRoot.currentArtist = tokens[1].trim() || "Artist";
                    leftMenuRoot.isPlayingTrack = (tokens[2].trim() === "Playing");
                    if (tokens.length >= 4 && tokens[3].trim() !== "") {
                        var rawUrl = tokens[3].trim();
                        if (rawUrl.indexOf("http://") === 0 || rawUrl.indexOf("https://") === 0 || rawUrl.indexOf("file://") === 0)
                            leftMenuRoot.currentCover = rawUrl;
                        else
                            leftMenuRoot.currentCover = "file://" + rawUrl;
                    } else {
                        leftMenuRoot.currentCover = leftMenuRoot.defaultCover;
                    }
                }
            }
        }
    }

    // ==========================================================
    // >>> WEATHER FETCH TIMER (direct API call, no cache file) <<<
    // ==========================================================
    Timer {
        interval: 900000 // 15 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: WeatherService.fetchWeather(leftMenuRoot.handleWeatherData)
    }

    // ==========================================================
    // >>> SCHEDULE FILE READER (local .json/.jsonc, re-read periodically) <<<
    // ==========================================================
    Process {
        id: scheduleReader
        command: ["cat", leftMenuRoot.schedulePath]
        running: false

        stdout: StdioCollector {
            onStreamFinished: leftMenuRoot.parseSchedule(text)
        }

        stderr: SplitParser {
            onRead: (line) => console.log("schedule read error: " + line)
        }
    }

    Timer {
        interval: 300000 // 5 minutes - picks up edits to the schedule file without a full reload
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!scheduleReader.running)
                scheduleReader.running = true;
        }
    }

    // ==========================================================
    // >>> HOMEWORK TRACKER STORAGE (local .json file, read/write) <<<
    // ==========================================================
    // FileView handles both loading and saving; setText() (called from
    // saveHomeworkData()) creates the file the first time a class or
    // assignment is added, so nothing needs to exist on disk beforehand.
    FileView {
        id: homeworkFileView
        path: leftMenuRoot.homeworkPath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: leftMenuRoot.parseHomeworkData(text())
    }

    // ==========================================================
    // >>> REAL AUDIO VISUALIZER DATA (cava, raw output mode) <<<
    // ==========================================================
    Process {
        id: cavaConfigWriter
        running: true
        command: ["sh", "-c",
            "mkdir -p " + Quickshell.env("HOME") + "/.config/quickshell_cava && printf " +
            "'[general]\\nbars = 40\\nframerate = 30\\nautosens = 1\\n" +
            "[input]\\nmethod = pipewire\\n" +
            "[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\n" +
            "ascii_max_range = 100\\nbar_delimiter = 59\\n" +
            "[smoothing]\\nnoise_reduction = 30\\n' > " +
            Quickshell.env("HOME") + "/.config/quickshell_cava/config"
        ]
        onExited: cavaProcess.running = leftSwipeView.currentIndex === 1
    }

    Process {
        id: cavaProcess
        running: false // flips on once the config is written above, and toggles with the tab (see Connections below)
        command: ["cava", "-p", Quickshell.env("HOME") + "/.config/quickshell_cava/config"]

        stdout: SplitParser {
            onRead: (line) => {
                if (!line || line.trim() === "")
                    return;
                var vals = line.split(';').filter(v => v.length > 0).map(Number);
                if (vals.length > 0)
                    leftMenuRoot.cavaLevels = vals;
            }
        }

        stderr: SplitParser {
            onRead: (line) => console.log("cava error: " + line)
        }
    }

    // Start/stop cava as the Player tab is opened/closed, instead of running constantly
    Connections {
        target: leftSwipeView
        function onCurrentIndexChanged() {
            cavaProcess.running = leftSwipeView.currentIndex === 1;
        }
    }

    // Background card inset by 16px horizontally to make room for fillets
    Rectangle {
        id: bgBase
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        color: Theme.bg0
        radius: 16
        z: -1
    }

    // Fillers for top squared corners connecting to top bar
    Rectangle {
        color: Theme.bg0
        width: 16
        height: 16
        anchors.top: bgBase.top
        anchors.left: bgBase.left
        z: -1
    }

    Rectangle {
        color: Theme.bg0
        width: 16
        height: 16
        anchors.top: bgBase.top
        anchors.right: bgBase.right
        z: -1
    }

    // Left Concave Fillet
    RoundedCorner {
        anchors.top: bgBase.top
        anchors.right: bgBase.left
        color: Theme.bg0
        size: 16
        corner: 2
        z: 10
    }

    // Right Concave Fillet
    RoundedCorner {
        anchors.top: bgBase.top
        anchors.left: bgBase.right
        color: Theme.bg0
        size: 16
        corner: 3
        z: 10
    }

    // Outer Master Layout Wrapper Container
    ColumnLayout {
        anchors.fill: bgBase
        anchors.margins: 10
        spacing: 8

        // Navigation Header
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Repeater {
                    model: 4

                    delegate: Rectangle {
                        width: index === leftSwipeView.currentIndex ? 16 : 6
                        height: 6
                        radius: 3
                        color: index === leftSwipeView.currentIndex ? Theme.rose : Theme.grey1
                        opacity: index === leftSwipeView.currentIndex ? 1 : 0.5

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

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Text {
                    text: "Weather"
                    color: leftSwipeView.currentIndex === 0 ? Theme.rose : "#6c7086"

                    font {
                        family: "Rubik"
                        pixelSize: 13
                        weight: Font.Bold
                    }

                    TapHandler {
                        onTapped: leftSwipeView.currentIndex = 0
                    }
                }

                Text {
                    text: "Player"
                    color: leftSwipeView.currentIndex === 1 ? Theme.rose : "#6c7086"

                    font {
                        family: "Rubik"
                        pixelSize: 13
                        weight: Font.Bold
                    }

                    TapHandler {
                        onTapped: leftSwipeView.currentIndex = 1
                    }
                }

                Text {
                    text: "Schedule"
                    color: leftSwipeView.currentIndex === 2 ? Theme.rose : "#6c7086"

                    font {
                        family: "Rubik"
                        pixelSize: 13
                        weight: Font.Bold
                    }

                    TapHandler {
                        onTapped: leftSwipeView.currentIndex = 2
                    }
                }

                Text {
                    text: "Homework"
                    color: leftSwipeView.currentIndex === 3 ? Theme.rose : "#6c7086"

                    font {
                        family: "Rubik"
                        pixelSize: 13
                        weight: Font.Bold
                    }

                    TapHandler {
                        onTapped: leftSwipeView.currentIndex = 3
                    }
                }
            }
        }

        // Swipe Content Panels
        SwipeView {
            id: leftSwipeView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // ==========================================================
            // PANEL 1: CELESTIA STYLE WEATHER PANEL
            // ==========================================================
            ColumnLayout {
                id: weatherTab
                spacing: 12

                // Light floating card wrapping the whole weather panel
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.bg1
                    radius: 18

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        // 1. TOP HERO SECTION (Location, Date, Sunrise/Sunset)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                Text {
                                    text: leftMenuRoot.locationName
                                    color: Theme.text
                                    font {
                                        family: "Rubik"
                                        pixelSize: 15
                                        weight: Font.Bold
                                    }
                                }

                                Text {
                                    text: Qt.formatDate(new Date(), "dddd, MMMM d")
                                    color: Theme.subText
                                    font {
                                        family: "Rubik"
                                        pixelSize: 9
                                    }
                                }
                            }

                            RowLayout {
                                spacing: 10
                                Layout.alignment: Qt.AlignRight

                                Row {
                                    spacing: 3
                                    Text {
                                        text: "󰖙"
                                        color: Theme.gold
                                        font { family: "Rubik"; pixelSize: 11 }
                                    }
                                    Column {
                                        Text {
                                            text: "Sunrise"
                                            color: Theme.text
                                            font { family: "Rubik"; pixelSize: 8 }
                                        }
                                        Text {
                                            text: leftMenuRoot.sunriseTime
                                            color: Theme.subText
                                            font { family: "Rubik"; pixelSize: 9; weight: Font.Medium }
                                        }
                                    }
                                }

                                Row {
                                    spacing: 3
                                    Text {
                                        text: "󰖔"
                                        color: Theme.foam
                                        font { family: "Rubik"; pixelSize: 11 }
                                    }
                                    Column {
                                        Text {
                                            text: "Sunset"
                                            color: Theme.text
                                            font { family: "Rubik"; pixelSize: 8 }
                                        }
                                        Text {
                                            text: leftMenuRoot.sunsetTime
                                            color: Theme.subText
                                            font { family: "Rubik"; pixelSize: 9; weight: Font.Medium }
                                        }
                                    }
                                }
                            }
                        }

                        // 2. MAIN WEATHER HERO BANNER
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 58
                            color: Theme.bg3
                            radius: 14

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Text {
                                    text: weatherIcon(leftMenuRoot.currentConditionCode)
                                    color: Theme.foam
                                    font { family: "Rubik"; pixelSize: 26 }
                                }

                                ColumnLayout {
                                    spacing: 0
                                    Text {
                                        text: leftMenuRoot.currentTemp
                                        color: Theme.iris
                                        font { family: "Rubik"; pixelSize: 20; weight: Font.Bold }
                                    }
                                    Text {
                                        text: leftMenuRoot.currentCondition
                                        color: Theme.text
                                        font { family: "Rubik"; pixelSize: 10; weight: Font.Medium }
                                    }
                                }
                            }
                        }

                        // 3. MID METRICS CARDS (Humidity, Feels Like, Wind)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                color: Theme.bg3
                                radius: 10

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        color: Theme.bg2
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰖘"
                                            color: Theme.pine
                                            font.pixelSize: 10
                                        }
                                    }
                                    Column {
                                        Text { text: "Humidity"; color: Theme.text; font.pixelSize: 8 }
                                        Text {
                                            text: leftMenuRoot.currentHumidity
                                            color: Theme.subText
                                            font { pixelSize: 10; weight: Font.Bold }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                color: Theme.bg3
                                radius: 10

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        color: Theme.bg2
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰔏"
                                            color: Theme.gold
                                            font.pixelSize: 10
                                        }
                                    }
                                    Column {
                                        Text { text: "Feels Like"; color: Theme.text; font.pixelSize: 8 }
                                        Text {
                                            text: leftMenuRoot.currentFeelsLike
                                            color: Theme.subText
                                            font { pixelSize: 10; weight: Font.Bold }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                color: Theme.bg3
                                radius: 10

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Rectangle {
                                        width: 20; height: 20; radius: 10
                                        color: Theme.bg2
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰖝"
                                            color: Theme.foam
                                            font.pixelSize: 10
                                        }
                                    }
                                    Column {
                                        Text { text: "Wind"; color: Theme.text; font.pixelSize: 8 }
                                        Text {
                                            text: leftMenuRoot.currentWind
                                            color: Theme.subText
                                            font { pixelSize: 10; weight: Font.Bold }
                                        }
                                    }
                                }
                            }
                        }

                        // 4. 7-DAY HORIZONTAL FORECAST CARDS
                        Text {
                            text: "7-Day Forecast"
                            color: Theme.text
                            font { family: "Rubik"; pixelSize: 10; weight: Font.Bold }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 5

                            Repeater {
                                model: leftMenuRoot.dailyData

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: index === 0 ? Theme.love: Theme.text
                                    border.color: index === 0 ? Theme.rose : "transparent"
                                    border.width: 1
                                    radius: 10

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        width: parent.width - 6
                                        spacing: 2

                                        Text {
                                            text: modelData.dayName
                                            color: index === 0 ? Theme.rose : Theme.bg0
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                            wrapMode: Text.WordWrap
                                            font { family: "Rubik"; pixelSize: 9; weight: Font.Bold }
                                        }
                                        Text {
                                            text: modelData.formattedDate
                                            color: Theme.subText
                                            Layout.alignment: Qt.AlignHCenter
                                            font { family: "Rubik"; pixelSize: 7 }
                                        }
                                        Text {
                                            text: modelData.icon
                                            color: Theme.rose
                                            Layout.alignment: Qt.AlignHCenter
                                            font { family: "Rubik"; pixelSize: 13 }
                                        }
                                        Text {
                                            text: modelData.tempRange
                                            color: Theme.subText
                                            Layout.alignment: Qt.AlignHCenter
                                            font { family: "Rubik"; pixelSize: 7; weight: Font.Medium }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================================
            // PANEL 2: MEDIA PLAYER
            // ==========================================================
            ColumnLayout {
                id: playerTab
                spacing: 12

                // Player card - shorter than the weather card; the outer
                // leftMenuRoot height itself animates between tabs (see
                // the Behavior on height near the top of the file)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.bg1
                    radius: 18

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 30
                        spacing: 32

                        // Circular album art with a real, cava-driven spike ring
                        Item {
                            id: artOrbit
                            Layout.preferredWidth: 140
                            Layout.preferredHeight: 140

                            Image {
                                id: coverArtImage
                                anchors.fill: parent
                                source: leftMenuRoot.currentCover
                                sourceSize.width: 140
                                sourceSize.height: 140
                                fillMode: Image.PreserveAspectCrop
                                opacity: 0
                                layer.enabled: true
                            }

                            Rectangle {
                                id: coverMask
                                anchors.fill: parent
                                radius: width / 2
                                opacity: 0
                                layer.enabled: true
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: coverArtImage
                                maskEnabled: true
                                maskSource: coverMask
                                visible: coverArtImage.status === Image.Ready
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: Theme.bg2
                                visible: coverArtImage.status !== Image.Ready

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰝚"
                                    color: Theme.subText
                                    font { family: "Rubik"; pixelSize: 30 }
                                }
                            }

                            // Real cava-driven spikes radiating around the circular art.
                            // model count MUST match `bars = 40` in the cava config above.
                            Item {
                                id: cavaRing
                                anchors.fill: parent
                                property real ringRadius: artOrbit.width / 2 + 5

                                Repeater {
                                    model: 40

                                    delegate: Item {
                                        anchors.centerIn: parent
                                        rotation: index * (360 / 40)

                                        Rectangle {
                                            id: spike
                                            property real rawLevel: (leftMenuRoot.cavaLevels[index] || 0)
                                            property real len: 5 + (rawLevel / 100) * 20

                                            width: 3
                                            radius: 1.5
                                            color: index % 2 === 0 ? Theme.rose : Theme.foam
                                            x: -width / 2
                                            y: -(cavaRing.ringRadius + len)
                                            height: len

                                            Behavior on len {
                                                NumberAnimation { duration: 70; easing.type: Easing.OutQuad }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Track info + transport controls
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 10

                            ColumnLayout {
                                spacing: 2
                                Layout.fillWidth: true

                                Text {
                                    text: leftMenuRoot.currentTitle
                                    color: Theme.text
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    font { family: "Rubik"; pixelSize: 16; weight: Font.Bold }
                                }

                                Text {
                                    text: leftMenuRoot.currentArtist
                                    color: Theme.subText
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    font { family: "Rubik"; pixelSize: 12 }
                                }
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 16

                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: Theme.text

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰒮"
                                        color: Theme.bg0
                                        font { family: "Rubik"; pixelSize: 12 }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        preventStealing: true
                                        onClicked: cmdPrev.running = true
                                    }
                                }

                                Rectangle {
                                    width: 36; height: 36; radius: 18
                                    color: Theme.pine

                                    Text {
                                        anchors.centerIn: parent
                                        text: leftMenuRoot.isPlayingTrack ? "" : ""
                                        color: Theme.text
                                        font { family: "Rubik"; pixelSize: 26 }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        preventStealing: true
                                        onClicked: cmdPlayPause.running = true
                                    }
                                }

                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: Theme.text

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰒭"
                                        color: Theme.bg0
                                        font { family: "Rubik"; pixelSize: 12 }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        preventStealing: true
                                        onClicked: cmdNext.running = true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================================
            // PANEL 3: SCHEDULE
            // ==========================================================
            ColumnLayout {
                id: scheduleTab
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.bg1
                    radius: 18

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        // Header: day name + date
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                Text {
                                    text: leftMenuRoot.todayLabel()
                                    color: Theme.text
                                    font { family: "Rubik"; pixelSize: 18; weight: Font.Bold }
                                }

                                Text {
                                    text: Qt.formatDate(new Date(), "MMMM d, yyyy")
                                    color: Theme.subText
                                    font { family: "Rubik"; pixelSize: 10 }
                                }
                            }

                            Text {
                                text: leftMenuRoot.todayEvents.length + (leftMenuRoot.todayEvents.length === 1 ? " event" : " events")
                                color: Theme.rose
                                font { family: "Rubik"; pixelSize: 11; weight: Font.Bold }
                            }
                        }

                        // Scrollable list of today's events
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ListView {
                                id: scheduleListView
                                anchors.fill: parent
                                clip: true
                                spacing: 6
                                model: leftMenuRoot.todayEvents

                                // On first build, jump straight to whichever event is
                                // "next" so it's already at the top without animating.
                                Component.onCompleted: {
                                    if (leftMenuRoot.nextEventIndex >= 0)
                                        positionViewAtIndex(leftMenuRoot.nextEventIndex, ListView.Beginning);
                                }

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 52
                                    radius: 12
                                    color: index === leftMenuRoot.nextEventIndex ? Theme.iris : Theme.bg3
                                    border.color: index === leftMenuRoot.nextEventIndex ? Theme.rose : "transparent"
                                    border.width: index === leftMenuRoot.nextEventIndex ? 2 : 0

                                    Behavior on color {
                                        ColorAnimation { duration: 200 }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 12

                                        Rectangle {
                                            Layout.preferredWidth: 4
                                            Layout.fillHeight: true
                                            radius: 2
                                            color: index === leftMenuRoot.nextEventIndex
                                                   ? Theme.bg0
                                                   : (index % 2 === 0 ? Theme.rose : Theme.foam)
                                        }

                                        // Title on top, time (single or range) underneath -
                                        // gives range strings like "9:00 AM - 10:30 AM"
                                        // enough room without crowding the title.
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                text: modelData.title || ""
                                                color: index === leftMenuRoot.nextEventIndex ? Theme.bg0 : Theme.text
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                font { family: "Rubik"; pixelSize: 12; weight: Font.Medium }
                                            }

                                            Text {
                                                text: modelData.time || ""
                                                color: index === leftMenuRoot.nextEventIndex ? Theme.bg0 : Theme.iris
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                                font { family: "Rubik"; pixelSize: 10; weight: Font.Bold }
                                            }
                                        }

                                        Text {
                                            visible: index === leftMenuRoot.nextEventIndex
                                            text: "NEXT"
                                            color: Theme.bg0
                                            font { family: "Rubik"; pixelSize: 9; weight: Font.Bold }
                                        }
                                    }
                                }

                                // Empty state
                                Text {
                                    anchors.centerIn: parent
                                    visible: leftMenuRoot.todayEvents.length === 0
                                    text: "Nothing scheduled today"
                                    color: Theme.subText
                                    font { family: "Rubik"; pixelSize: 12 }
                                }
                            }

                            // Soft fade to the card's background color at the bottom edge,
                            // so a partially-scrolled item tapers off instead of hard-cutting.
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 28
                                visible: scheduleListView.contentHeight > scheduleListView.height

                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: "transparent" }
                                    GradientStop { position: 1.0; color: Theme.bg1 }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================================
            // PANEL 4: HOMEWORK TRACKER
            // ==========================================================
            ColumnLayout {
                id: homeworkTab
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.bg1
                    radius: 18

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        // Header: title + assignment count + gear/add buttons
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true

                                Text {
                                    text: "Homework"
                                    color: Theme.text
                                    font { family: "Rubik"; pixelSize: 15; weight: Font.Bold }
                                }

                                Text {
                                    text: leftMenuRoot.homeworkAssignments.length + (leftMenuRoot.homeworkAssignments.length === 1 ? " assignment" : " assignments")
                                    color: Theme.subText
                                    font { family: "Rubik"; pixelSize: 9 }
                                }
                            }

                            Rectangle {
                                width: 26; height: 26; radius: 13
                                color: leftMenuRoot.homeworkManageClassesVisible ? Theme.iris : Theme.bg3

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒓"
                                    color: leftMenuRoot.homeworkManageClassesVisible ? Theme.bg0 : Theme.text
                                    font { family: "Rubik"; pixelSize: 12 }
                                }

                                TapHandler {
                                    onTapped: {
                                        leftMenuRoot.homeworkManageClassesVisible = !leftMenuRoot.homeworkManageClassesVisible;
                                        if (leftMenuRoot.homeworkManageClassesVisible)
                                            leftMenuRoot.homeworkAddFormVisible = false;
                                    }
                                }
                            }

                            Rectangle {
                                width: 26; height: 26; radius: 13
                                color: leftMenuRoot.homeworkAddFormVisible ? Theme.rose : Theme.pine

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰐕"
                                    color: Theme.bg0
                                    font { family: "Rubik"; pixelSize: 14; weight: Font.Bold }
                                }

                                TapHandler {
                                    onTapped: {
                                        leftMenuRoot.homeworkAddFormVisible = !leftMenuRoot.homeworkAddFormVisible;
                                        if (leftMenuRoot.homeworkAddFormVisible) {
                                            leftMenuRoot.homeworkManageClassesVisible = false;
                                            leftMenuRoot.resetHwDueDateWheels();
                                        } else {
                                            leftMenuRoot.hwFormTitle = "";
                                            leftMenuRoot.hwFormClassId = "";
                                            leftMenuRoot.hwFormDueDate = "";
                                        }
                                    }
                                }
                            }
                        }

                        // ---- Add-assignment form ----
                        // Wrapped in a ScrollView so the Add Assignment button is
                        // always reachable regardless of homeworkPanelHeight - the
                        // form scrolls internally instead of getting clipped.
                        ScrollView {
                            id: addFormScrollView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            visible: leftMenuRoot.homeworkAddFormVisible

                            ColumnLayout {
                                width: addFormScrollView.availableWidth
                                spacing: 8

                            TextField {
                                Layout.fillWidth: true
                                placeholderText: "Assignment title"
                                text: leftMenuRoot.hwFormTitle
                                onTextChanged: leftMenuRoot.hwFormTitle = text
                                font { family: "Rubik"; pixelSize: 11 }
                            }

                            Text {
                                text: "Class"
                                color: Theme.subText
                                font { family: "Rubik"; pixelSize: 9; weight: Font.Bold }
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    height: 26
                                    radius: 8
                                    width: noneChipLabel.implicitWidth + 16
                                    color: Theme.bg2
                                    border.width: 2
                                    border.color: leftMenuRoot.hwFormClassId === "" ? Theme.text : "transparent"

                                    Text {
                                        id: noneChipLabel
                                        anchors.centerIn: parent
                                        text: "None"
                                        color: Theme.subText
                                        font { family: "Rubik"; pixelSize: 10; weight: Font.Bold }
                                    }

                                    TapHandler {
                                        onTapped: leftMenuRoot.hwFormClassId = ""
                                    }
                                }

                                Repeater {
                                    model: leftMenuRoot.homeworkClasses

                                    delegate: Rectangle {
                                        height: 26
                                        radius: 8
                                        width: classChipLabel.implicitWidth + 16
                                        color: modelData.color
                                        border.width: 2
                                        border.color: leftMenuRoot.hwFormClassId === modelData.id ? Theme.text : "transparent"

                                        Text {
                                            id: classChipLabel
                                            anchors.centerIn: parent
                                            text: modelData.name
                                            color: Theme.bg0
                                            elide: Text.ElideRight
                                            font { family: "Rubik"; pixelSize: 10; weight: Font.Bold }
                                        }

                                        TapHandler {
                                            onTapped: leftMenuRoot.hwFormClassId = modelData.id
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: leftMenuRoot.homeworkClasses.length === 0
                                text: "No classes yet — add one with the gear icon"
                                color: Theme.subText
                                font { family: "Rubik"; pixelSize: 8 }
                            }

                            Text {
                                text: "Due date"
                                color: Theme.subText
                                font { family: "Rubik"; pixelSize: 9; weight: Font.Bold }
                            }

                            // iOS-style scrolling wheel picker (Month / Day / Year),
                            // like the native birthday picker. Wheels write into
                            // hwFormDue{Year,Month,Day} -> hwFormDueDate ("YYYY-MM-DD").
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 90

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 28
                                    radius: 8
                                    color: Theme.bg3
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 4

                                    Tumbler {
                                        id: hwMonthTumbler
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        visibleItemCount: 3
                                        model: 12
                                        currentIndex: leftMenuRoot.hwFormDueMonth - 1
                                        onCurrentIndexChanged: {
                                            leftMenuRoot.hwFormDueMonth = currentIndex + 1;
                                            leftMenuRoot.updateHwFormDueDateFromParts();
                                        }
                                        // Custom contentItem so we control the snap speed
                                        // directly (highlightMoveDuration) instead of relying
                                        // on whatever the QQC2 style's default happens to be.
                                        contentItem: PathView {
                                            id: hwMonthPathView
                                            model: hwMonthTumbler.model
                                            delegate: hwMonthTumbler.delegate
                                            clip: true
                                            pathItemCount: hwMonthTumbler.visibleItemCount + 1
                                            preferredHighlightBegin: 0.5
                                            preferredHighlightEnd: 0.5
                                            highlightRangeMode: PathView.StrictlyEnforceRange
                                            highlightMoveDuration: 90
                                            property real delegateHeight: hwMonthTumbler.availableHeight / hwMonthTumbler.visibleItemCount

                                            path: Path {
                                                startX: hwMonthPathView.width / 2
                                                startY: -hwMonthPathView.delegateHeight / 2
                                                PathLine {
                                                    x: hwMonthPathView.width / 2
                                                    y: hwMonthPathView.pathItemCount * hwMonthPathView.delegateHeight - hwMonthPathView.delegateHeight / 2
                                                }
                                            }
                                        }
                                        delegate: Item {
                                            width: hwMonthTumbler.width
                                            height: hwMonthTumbler.height / hwMonthTumbler.visibleItemCount

                                            Text {
                                                anchors.fill: parent
                                                text: Qt.locale().monthName(index, Locale.ShortFormat)
                                                color: Theme.text
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                opacity: 1.0 - Math.min(Math.abs(Tumbler.displacement), 2) * 0.35
                                                font { family: "Rubik"; pixelSize: 12; weight: Font.Bold }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: Tumbler.tumbler.currentIndex = index
                                            }
                                        }
                                    }

                                    Tumbler {
                                        id: hwDayTumbler
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        visibleItemCount: 3
                                        model: leftMenuRoot.daysInMonth(leftMenuRoot.hwFormDueYear, leftMenuRoot.hwFormDueMonth)
                                        currentIndex: leftMenuRoot.hwFormDueDay - 1
                                        onCurrentIndexChanged: {
                                            leftMenuRoot.hwFormDueDay = currentIndex + 1;
                                            leftMenuRoot.updateHwFormDueDateFromParts();
                                        }
                                        contentItem: PathView {
                                            id: hwDayPathView
                                            model: hwDayTumbler.model
                                            delegate: hwDayTumbler.delegate
                                            clip: true
                                            pathItemCount: hwDayTumbler.visibleItemCount + 1
                                            preferredHighlightBegin: 0.5
                                            preferredHighlightEnd: 0.5
                                            highlightRangeMode: PathView.StrictlyEnforceRange
                                            highlightMoveDuration: 90
                                            property real delegateHeight: hwDayTumbler.availableHeight / hwDayTumbler.visibleItemCount

                                            path: Path {
                                                startX: hwDayPathView.width / 2
                                                startY: -hwDayPathView.delegateHeight / 2
                                                PathLine {
                                                    x: hwDayPathView.width / 2
                                                    y: hwDayPathView.pathItemCount * hwDayPathView.delegateHeight - hwDayPathView.delegateHeight / 2
                                                }
                                            }
                                        }
                                        delegate: Item {
                                            width: hwDayTumbler.width
                                            height: hwDayTumbler.height / hwDayTumbler.visibleItemCount

                                            Text {
                                                anchors.fill: parent
                                                text: index + 1
                                                color: Theme.text
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                opacity: 1.0 - Math.min(Math.abs(Tumbler.displacement), 2) * 0.35
                                                font { family: "Rubik"; pixelSize: 12; weight: Font.Bold }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: Tumbler.tumbler.currentIndex = index
                                            }
                                        }
                                    }

                                    Tumbler {
                                        id: hwYearTumbler
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        visibleItemCount: 3
                                        // This year plus the next 4 - plenty of runway for due dates
                                        model: 5
                                        currentIndex: leftMenuRoot.hwFormDueYear - new Date().getFullYear()
                                        onCurrentIndexChanged: {
                                            leftMenuRoot.hwFormDueYear = new Date().getFullYear() + currentIndex;
                                            leftMenuRoot.updateHwFormDueDateFromParts();
                                        }
                                        contentItem: PathView {
                                            id: hwYearPathView
                                            model: hwYearTumbler.model
                                            delegate: hwYearTumbler.delegate
                                            clip: true
                                            pathItemCount: hwYearTumbler.visibleItemCount + 1
                                            preferredHighlightBegin: 0.5
                                            preferredHighlightEnd: 0.5
                                            highlightRangeMode: PathView.StrictlyEnforceRange
                                            highlightMoveDuration: 90
                                            property real delegateHeight: hwYearTumbler.availableHeight / hwYearTumbler.visibleItemCount

                                            path: Path {
                                                startX: hwYearPathView.width / 2
                                                startY: -hwYearPathView.delegateHeight / 2
                                                PathLine {
                                                    x: hwYearPathView.width / 2
                                                    y: hwYearPathView.pathItemCount * hwYearPathView.delegateHeight - hwYearPathView.delegateHeight / 2
                                                }
                                            }
                                        }
                                        delegate: Item {
                                            width: hwYearTumbler.width
                                            height: hwYearTumbler.height / hwYearTumbler.visibleItemCount

                                            Text {
                                                anchors.fill: parent
                                                text: new Date().getFullYear() + index
                                                color: Theme.text
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                opacity: 1.0 - Math.min(Math.abs(Tumbler.displacement), 2) * 0.35
                                                font { family: "Rubik"; pixelSize: 12; weight: Font.Bold }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: Tumbler.tumbler.currentIndex = index
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 10
                                color: Theme.pine

                                Text {
                                    anchors.centerIn: parent
                                    text: "Add Assignment"
                                    color: Theme.bg0
                                    font { family: "Rubik"; pixelSize: 11; weight: Font.Bold }
                                }

                                TapHandler {
                                    onTapped: {
                                        if (leftMenuRoot.hwFormTitle.trim() === "")
                                            return;
                                        leftMenuRoot.addHomeworkAssignment(leftMenuRoot.hwFormTitle, leftMenuRoot.hwFormClassId, leftMenuRoot.hwFormDueDate);
                                        leftMenuRoot.hwFormTitle = "";
                                        leftMenuRoot.hwFormClassId = "";
                                        leftMenuRoot.resetHwDueDateWheels();
                                        leftMenuRoot.homeworkAddFormVisible = false;
                                    }
                                }
                            }
                            }
                        }

                        // ---- Manage-classes form ----
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: leftMenuRoot.homeworkManageClassesVisible
                            spacing: 8

                            Text {
                                text: "Classes"
                                color: Theme.subText
                                font { family: "Rubik"; pixelSize: 9; weight: Font.Bold }
                            }

                            ScrollView {
                                id: classesScrollView
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true

                                ColumnLayout {
                                    width: classesScrollView.availableWidth
                                    spacing: 6

                                    Repeater {
                                        model: leftMenuRoot.homeworkClasses

                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            height: 30
                                            radius: 8
                                            color: Theme.bg3

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 6
                                                spacing: 8

                                                Rectangle {
                                                    width: 14; height: 14; radius: 7
                                                    color: modelData.color
                                                }

                                                Text {
                                                    text: modelData.name
                                                    color: Theme.text
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                    font { family: "Rubik"; pixelSize: 10; weight: Font.Medium }
                                                }

                                                Text {
                                                    text: "×"
                                                    color: Theme.subText
                                                    font { family: "Rubik"; pixelSize: 12; weight: Font.Bold }

                                                    TapHandler {
                                                        onTapped: leftMenuRoot.deleteHomeworkClass(modelData.id)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        visible: leftMenuRoot.homeworkClasses.length === 0
                                        text: "No classes yet"
                                        color: Theme.subText
                                        font { family: "Rubik"; pixelSize: 9 }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.bg3
                            }

                            TextField {
                                Layout.fillWidth: true
                                placeholderText: "New class name"
                                text: leftMenuRoot.hwNewClassName
                                onTextChanged: leftMenuRoot.hwNewClassName = text
                                font { family: "Rubik"; pixelSize: 11 }
                            }

                            Row {
                                spacing: 6

                                Repeater {
                                    model: leftMenuRoot.homeworkColorPalette

                                    delegate: Rectangle {
                                        width: 22; height: 22; radius: 11
                                        color: modelData
                                        border.width: 2
                                        border.color: (leftMenuRoot.hwNewClassColor !== "" && Qt.colorEqual(modelData, leftMenuRoot.hwNewClassColor)) ? Theme.text : "transparent"

                                        TapHandler {
                                            onTapped: leftMenuRoot.hwNewClassColor = modelData
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                radius: 10
                                color: Theme.pine

                                Text {
                                    anchors.centerIn: parent
                                    text: "Add Class"
                                    color: Theme.bg0
                                    font { family: "Rubik"; pixelSize: 11; weight: Font.Bold }
                                }

                                TapHandler {
                                    onTapped: {
                                        if (leftMenuRoot.hwNewClassName.trim() === "")
                                            return;
                                        var chosenColor = leftMenuRoot.hwNewClassColor || leftMenuRoot.homeworkColorPalette[0];
                                        leftMenuRoot.addHomeworkClass(leftMenuRoot.hwNewClassName, chosenColor);
                                        leftMenuRoot.hwNewClassName = "";
                                    }
                                }
                            }
                        }

                        // ---- 3-column "newspaper flow" assignment list ----
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: !leftMenuRoot.homeworkAddFormVisible && !leftMenuRoot.homeworkManageClassesVisible

                            Text {
                                anchors.centerIn: parent
                                visible: leftMenuRoot.homeworkAssignments.length === 0
                                text: "No homework yet — tap + to add one"
                                color: Theme.subText
                                font { family: "Rubik"; pixelSize: 11 }
                            }

                            ScrollView {
                                id: homeworkListScrollView
                                anchors.fill: parent
                                clip: true
                                visible: leftMenuRoot.homeworkAssignments.length > 0

                                RowLayout {
                                    width: homeworkListScrollView.availableWidth
                                    spacing: 8

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignTop
                                        spacing: 6

                                        Repeater {
                                            model: leftMenuRoot.homeworkColumn1

                                            delegate: Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 54
                                                radius: 10
                                                color: modelData.done ? Theme.bg2 : Theme.bg3
                                                opacity: modelData.done ? 0.55 : 1

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 8
                                                    spacing: 8

                                                    Rectangle {
                                                        Layout.preferredWidth: 4
                                                        Layout.fillHeight: true
                                                        radius: 2
                                                        color: leftMenuRoot.homeworkClassColor(modelData.classId)
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 1

                                                        Text {
                                                            text: modelData.title
                                                            color: Theme.text
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                            font { family: "Rubik"; pixelSize: 11; weight: Font.Bold; strikeout: modelData.done }
                                                        }

                                                        Text {
                                                            text: leftMenuRoot.homeworkClassName(modelData.classId)
                                                            color: leftMenuRoot.homeworkClassColor(modelData.classId)
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                            font { family: "Rubik"; pixelSize: 8; weight: Font.Medium }
                                                        }

                                                        Text {
                                                            text: leftMenuRoot.dueDateLabel(modelData.dueDate)
                                                            color: (!modelData.done && leftMenuRoot.daysUntilDue(modelData.dueDate) !== null && leftMenuRoot.daysUntilDue(modelData.dueDate) < 0) ? Theme.love : Theme.subText
                                                            font { family: "Rubik"; pixelSize: 8 }
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        spacing: 4

                                                        Text {
                                                            text: modelData.done ? "󰄲" : "󰄱"
                                                            color: Theme.pine
                                                            font { family: "Rubik"; pixelSize: 13 }

                                                            TapHandler {
                                                                onTapped: leftMenuRoot.toggleHomeworkDone(modelData.id)
                                                            }
                                                        }

                                                        Text {
                                                            text: "×"
                                                            color: Theme.subText
                                                            font { family: "Rubik"; pixelSize: 13; weight: Font.Bold }

                                                            TapHandler {
                                                                onTapped: leftMenuRoot.deleteHomeworkAssignment(modelData.id)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignTop
                                        spacing: 6

                                        Repeater {
                                            model: leftMenuRoot.homeworkColumn2

                                            delegate: Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 54
                                                radius: 10
                                                color: modelData.done ? Theme.bg2 : Theme.bg3
                                                opacity: modelData.done ? 0.55 : 1

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 8
                                                    spacing: 8

                                                    Rectangle {
                                                        Layout.preferredWidth: 4
                                                        Layout.fillHeight: true
                                                        radius: 2
                                                        color: leftMenuRoot.homeworkClassColor(modelData.classId)
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 1

                                                        Text {
                                                            text: modelData.title
                                                            color: Theme.text
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                            font { family: "Rubik"; pixelSize: 11; weight: Font.Bold; strikeout: modelData.done }
                                                        }

                                                        Text {
                                                            text: leftMenuRoot.homeworkClassName(modelData.classId)
                                                            color: leftMenuRoot.homeworkClassColor(modelData.classId)
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                            font { family: "Rubik"; pixelSize: 8; weight: Font.Medium }
                                                        }

                                                        Text {
                                                            text: leftMenuRoot.dueDateLabel(modelData.dueDate)
                                                            color: (!modelData.done && leftMenuRoot.daysUntilDue(modelData.dueDate) !== null && leftMenuRoot.daysUntilDue(modelData.dueDate) < 0) ? Theme.love : Theme.subText
                                                            font { family: "Rubik"; pixelSize: 8 }
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        spacing: 4

                                                        Text {
                                                            text: modelData.done ? "󰄲" : "󰄱"
                                                            color: Theme.pine
                                                            font { family: "Rubik"; pixelSize: 13 }

                                                            TapHandler {
                                                                onTapped: leftMenuRoot.toggleHomeworkDone(modelData.id)
                                                            }
                                                        }

                                                        Text {
                                                            text: "×"
                                                            color: Theme.subText
                                                            font { family: "Rubik"; pixelSize: 13; weight: Font.Bold }

                                                            TapHandler {
                                                                onTapped: leftMenuRoot.deleteHomeworkAssignment(modelData.id)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignTop
                                        spacing: 6

                                        Repeater {
                                            model: leftMenuRoot.homeworkColumn3

                                            delegate: Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 54
                                                radius: 10
                                                color: modelData.done ? Theme.bg2 : Theme.bg3
                                                opacity: modelData.done ? 0.55 : 1

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.margins: 8
                                                    spacing: 8

                                                    Rectangle {
                                                        Layout.preferredWidth: 4
                                                        Layout.fillHeight: true
                                                        radius: 2
                                                        color: leftMenuRoot.homeworkClassColor(modelData.classId)
                                                    }

                                                    ColumnLayout {
                                                        Layout.fillWidth: true
                                                        spacing: 1

                                                        Text {
                                                            text: modelData.title
                                                            color: Theme.text
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                            font { family: "Rubik"; pixelSize: 11; weight: Font.Bold; strikeout: modelData.done }
                                                        }

                                                        Text {
                                                            text: leftMenuRoot.homeworkClassName(modelData.classId)
                                                            color: leftMenuRoot.homeworkClassColor(modelData.classId)
                                                            elide: Text.ElideRight
                                                            Layout.fillWidth: true
                                                            font { family: "Rubik"; pixelSize: 8; weight: Font.Medium }
                                                        }

                                                        Text {
                                                            text: leftMenuRoot.dueDateLabel(modelData.dueDate)
                                                            color: (!modelData.done && leftMenuRoot.daysUntilDue(modelData.dueDate) !== null && leftMenuRoot.daysUntilDue(modelData.dueDate) < 0) ? Theme.love : Theme.subText
                                                            font { family: "Rubik"; pixelSize: 8 }
                                                        }
                                                    }

                                                    ColumnLayout {
                                                        spacing: 4

                                                        Text {
                                                            text: modelData.done ? "󰄲" : "󰄱"
                                                            color: Theme.pine
                                                            font { family: "Rubik"; pixelSize: 13 }

                                                            TapHandler {
                                                                onTapped: leftMenuRoot.toggleHomeworkDone(modelData.id)
                                                            }
                                                        }

                                                        Text {
                                                            text: "×"
                                                            color: Theme.subText
                                                            font { family: "Rubik"; pixelSize: 13; weight: Font.Bold }

                                                            TapHandler {
                                                                onTapped: leftMenuRoot.deleteHomeworkAssignment(modelData.id)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
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
