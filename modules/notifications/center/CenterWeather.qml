import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../globalstate"
import "../../theme"
import "../../weather/weatherService.js" as WeatherService

// Weather tile for the notification center: current conditions + the next 7 days.
// Uses the same WeatherService / LocaleConfig / ServicesConfig the weather widget.
Rectangle {
    id: root

    property string temp: "--"
    property string icon: ""
    property string hiLo: ""
    property var days: []

    implicitHeight: content.implicitHeight + 20
    radius: 14
    color: Theme.bg1

    readonly property var weekdays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    function dayName(dateStr, i) {
        if (i === 0)
            return "Today";
        return weekdays[new Date(dateStr + "T00:00:00").getDay()];
    }

    function handleWeatherData(data) {
        try {
            const d = data.daily;
            const unit = "°";

            // current temp/code: use whatever "current" block the API returned, else today's daily
            const cur = data.current ?? data.current_weather ?? {};
            const curTemp = cur.temperature_2m ?? cur.temperature
                ?? (d ? (d.temperature_2m_max[0] + d.temperature_2m_min[0]) / 2 : undefined);
            const curCode = cur.weather_code ?? cur.weathercode ?? (d ? d.weather_code[0] : undefined);

            if (curTemp !== undefined)
                root.temp = Math.round(curTemp) + unit;
            if (curCode !== undefined)
                root.icon = WeatherService.getWeatherIcon(curCode);

            if (!d || !d.time)
                return;

            const today = new Date();
            today.setHours(0, 0, 0, 0);

            const list = [];
            for (let i = 0; i < d.time.length; i++) {
                const date = new Date(d.time[i] + "T00:00:00");
                if (date.getTime() < today.getTime())
                    continue;
                list.push({
                    name: root.dayName(d.time[i], list.length),
                    icon: WeatherService.getWeatherIcon(d.weather_code[i]),
                    max: Math.round(d.temperature_2m_max[i]) + unit,
                    min: Math.round(d.temperature_2m_min[i]) + unit
                });
            }

            if (list.length > 0)
                root.hiLo = "H " + list[0].max + "  L " + list[0].min;
            root.days = list.slice(0, 7);
        } catch (e) {
            console.log("CenterWeather parse error: " + e);
        }
    }

    function refresh() {
        WeatherService.fetchWeatherForLocation(LocaleConfig.weatherLocation, LocaleConfig.useFahrenheit, root.handleWeatherData);
    }

    Timer {
        id: pollTimer
        interval: ServicesConfig.weatherPollMinutes * 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Connections {
        target: LocaleConfig
        function onWeatherLocationChanged() { root.refresh(); }
        function onUseFahrenheitChanged() { root.refresh(); }
    }

    Connections {
        target: ServicesConfig
        function onWeatherPollMinutesChanged() { pollTimer.restart(); }
    }

    ColumnLayout {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 10

        // ── now ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                font.family: "Rubik"
                text: root.icon
                color: Theme.gold
                font.pixelSize: 30
            }

            ColumnLayout {
                spacing: 0

                Text {
                    font.family: "Rubik"
                    text: root.temp
                    color: Theme.text
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                }
                Text {
                    font.family: "Rubik"
                    text: root.hiLo
                    color: Theme.subText
                    font.pixelSize: 11
                    visible: text !== ""
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                font.family: "Rubik"
                Layout.alignment: Qt.AlignTop
                Layout.maximumWidth: 120
                text: LocaleConfig.weatherLocation ?? ""
                color: Theme.subText
                font.pixelSize: 11
                font.weight: Font.Medium
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
            }
        }

        // ── next days ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 20 //CHANGE SPACING BETWEEN DAYS
            visible: root.days.length > 0

            Repeater {
                model: root.days

                delegate: ColumnLayout {
                    required property var modelData

                    // equal-width columns spread across the whole tile
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    spacing: 2

                    Text {
                        font.family: "Rubik"
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.name
                        color: Theme.subText
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                    Text {
                        font.family: "Rubik"
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.icon
                        color: Theme.foam
                        font.pixelSize: 15
                    }
                    Text {
                        font.family: "Rubik"
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.max
                        color: Theme.text
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                    Text {
                        font.family: "Rubik"
                        Layout.alignment: Qt.AlignHCenter
                        text: modelData.min
                        color: Theme.placeholder
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
