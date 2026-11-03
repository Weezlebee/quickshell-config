import "../globalstate"
import QtQuick
import QtQuick.Layouts
import Quickshell
import "weatherService.js" as WeatherService
import "../globalstate"

Item {
    id: forecastRoot

    property var dailyData: []

    function getDayName(dateStr) {
        var date = new Date(dateStr + 'T00:00:00');
        var today = new Date();
        date.setHours(0, 0, 0, 0);
        today.setHours(0, 0, 0, 0);
        if (date.getTime() === today.getTime())
            return 'Today';

        return date.toLocaleDateString('en-US', {
            "weekday": 'short'
        });
    }

    function formatShortDate(dateStr) {
        var date = new Date(dateStr + 'T00:00:00');
        return date.toLocaleDateString('en-US', {
            "month": 'short',
            "day": 'numeric'
        });
    }

    function handleWeatherData(data) {
        try {
            var d = data.daily;
            if (!d || !d.time)
                return ;

            var list = [];
            var todayBaseline = new Date();
            todayBaseline.setHours(0, 0, 0, 0);
            for (var i = 0; i < d.time.length; i++) {
                var checkDate = new Date(d.time[i] + 'T00:00:00');
                checkDate.setHours(0, 0, 0, 0);
                if (checkDate.getTime() >= todayBaseline.getTime())
                    list.push({
                        "dayName": getDayName(d.time[i]),
                        "formattedDate": formatShortDate(d.time[i]),
                        "icon": WeatherService.getWeatherIcon(d.weather_code[i]),
                        "tempRange": Math.round(d.temperature_2m_min[i]) + "° / " + Math.round(d.temperature_2m_max[i]) + "°"
                    });

            }
            forecastRoot.dailyData = list.slice(0, 7);
        } catch (e) {
            console.log("Forecast parse error: " + e);
        }
    }

    function refresh() {
        WeatherService.fetchWeatherForLocation(LocaleConfig.weatherLocation, LocaleConfig.useFahrenheit, forecastRoot.handleWeatherData);
    }

    implicitWidth: 550
    implicitHeight: 150

    Connections {
        function onWeatherLocationChanged() {
            forecastRoot.refresh();
        }

        function onUseFahrenheitChanged() {
            forecastRoot.refresh();
        }

        target: LocaleConfig
    }

    Timer {
        id: pollTimer
        interval: ServicesConfig.weatherPollMinutes * 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: forecastRoot.refresh()
    }

    Connections {
        target: ServicesConfig
        function onWeatherPollMinutesChanged() { pollTimer.restart(); }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            text: "7-Day Forecast"
            color: "#1e2a32"

            font {
                family: "Rubik"
                pixelSize: 14
                weight: Font.Bold
            }

        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            Repeater {
                model: forecastRoot.dailyData

                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: index === 0 ? "#e3f3f1" : "#ffffff"
                    border.color: index === 0 ? "#12877f" : "transparent"
                    border.width: 1
                    radius: 12

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: modelData.dayName
                            color: index === 0 ? "#12877f" : "#1e2a32"
                            Layout.alignment: Qt.AlignHCenter

                            font {
                                family: "Rubik"
                                pixelSize: 11
                                weight: Font.Bold
                            }

                        }

                        Text {
                            text: modelData.formattedDate
                            color: "#7c8894"
                            Layout.alignment: Qt.AlignHCenter

                            font {
                                family: "Rubik"
                                pixelSize: 9
                            }

                        }

                        Text {
                            text: modelData.icon
                            color: "#12877f"
                            Layout.alignment: Qt.AlignHCenter

                            font {
                                family: "Rubik"
                                pixelSize: 16
                            }

                        }

                        Text {
                            text: modelData.tempRange
                            color: "#1e2a32"
                            Layout.alignment: Qt.AlignHCenter

                            font {
                                family: "Rubik"
                                pixelSize: 9
                                weight: Font.Medium
                            }

                        }

                    }

                }

            }

        }

    }

}
