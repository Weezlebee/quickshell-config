// weatherService.js
// Fetches live weather from Open-Meteo, geocoding a location name into
// coordinates first. Hands parsed JSON back to QML via a callback.

const DEFAULT_LATITUDE = "42.3601";
const DEFAULT_LONGITUDE = "-71.0589";

// In-memory cache so repeated calls for the same location name don't
// re-hit the geocoding API every 15 minutes.
var geocodeCache = {};

function geocodeLocation(name, callback) {
    if (!name || name.trim() === "") {
        callback(null);
        return;
    }
    if (geocodeCache[name]) {
        callback(geocodeCache[name]);
        return;
    }

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    if (response.results && response.results.length > 0) {
                        var r = response.results[0];
                        var coords = { latitude: r.latitude, longitude: r.longitude, name: r.name };
                        geocodeCache[name] = coords;
                        callback(coords);
                    } else {
                        console.log("Geocode: no results for " + name);
                        callback(null);
                    }
                } catch (e) {
                    console.log("Geocode parse error: " + e);
                    callback(null);
                }
            } else {
                console.log("Geocode API error: " + xhr.status);
                callback(null);
            }
        }
    };
    xhr.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + encodeURIComponent(name));
    xhr.send();
}

function fetchWeather(callback, options) {
    options = options || {};
    var lat = options.latitude || DEFAULT_LATITUDE;
    var lon = options.longitude || DEFAULT_LONGITUDE;
    var unit = options.useFahrenheit ? "fahrenheit" : "celsius";

    var url =
        "https://api.open-meteo.com/v1/forecast" +
        "?latitude=" + lat +
        "&longitude=" + lon +
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m" +
        "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset" +
        "&temperature_unit=" + unit +
        "&timezone=auto";

    var xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    callback(response);
                } catch (e) {
                    console.log("Weather parse error: " + e);
                }
            } else {
                console.log("Weather API error: " + xhr.status);
            }
        }
    };
    xhr.open("GET", url);
    xhr.send();
}

// Convenience: resolve a location name to coordinates, then fetch weather.
// Falls back to the default coordinates if geocoding fails or the name is empty.
function fetchWeatherForLocation(locationName, useFahrenheit, callback) {
    geocodeLocation(locationName, function (coords) {
        var opts = { useFahrenheit: useFahrenheit };
        if (coords) {
            opts.latitude = coords.latitude;
            opts.longitude = coords.longitude;
        }
        fetchWeather(callback, opts);
    });
}

function getWeatherIcon(code) {
    if (code === 0) return '󰖙';   // sunny
    if (code <= 2) return '󰖕';    // partly cloudy
    if (code === 3) return '󰖐';   // cloudy
    if (code <= 48) return '󰖑';   // foggy
    if (code <= 57) return '󰼳';   // drizzle
    if (code <= 67) return '󰖗';   // rain
    if (code <= 77) return '󰖘';   // snow
    if (code <= 82) return '󰖖';   // showers
    if (code <= 86) return '󰙿';   // snowy rainy
    if (code <= 99) return '󰙾';   // thunderstorm
    return '󰖙';
}

function getConditionText(code) {
    if (code === 0) return 'Clear Sky';
    if (code <= 2) return 'Partly Cloudy';
    if (code === 3) return 'Overcast';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Showers';
    if (code <= 99) return 'Thunderstorm';
    return 'Clear';
}