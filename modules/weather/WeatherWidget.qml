import QtQuick
import QtQuick.Layouts
import "weatherService.js" as WeatherService
import "../theme"
import "../globalstate"

RowLayout {
    id: root
    spacing: 6

    property string temperature: "--°"
    property string weatherIcon: "󰖙"

    

    function refresh() {
        WeatherService.fetchWeatherForLocation(LocaleConfig.weatherLocation, LocaleConfig.useFahrenheit, function (data) {
            if (!data || !data.current) return;
            var temp = data.current.temperature_2m;
            var code = data.current.weather_code;
            var unit = LocaleConfig.useFahrenheit ? "°F" : "°C";
            root.temperature = Math.round(temp) + unit;
            root.weatherIcon = WeatherService.getWeatherIcon(code);
        });
    }

    Text {
        text: root.weatherIcon
        color: Theme.foam
        font.pixelSize: 14
    }

    Text {
        text: root.temperature
        color: Theme.text
        font.pixelSize: 14
        font.bold: true
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

    Timer {
        id: pollTimer
        interval: ServicesConfig.weatherPollMinutes * 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    
}