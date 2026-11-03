#!/bin/bash

NMCLI=/usr/bin/nmcli

# 1. Fetch active SSID connection
active_wifi=$("$NMCLI" -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
if [ -z "$active_wifi" ]; then
    active_wifi="Disconnected"
fi

# 2. Trigger a fresh scan
"$NMCLI" device wifi rescan >/dev/null 2>&1
sleep 1

# 3. Fetch only wifi connection profiles stored on disk
known_networks=$("$NMCLI" -t -f name,type connection show | awk -F: '$2=="802-11-wireless"{print $1}')

# 4. Read raw wifi data, drop blanks, sort by strength, dedupe
wifi_list=$("$NMCLI" -t -f ssid,signal dev wifi list --rescan no | sort -t: -k2 -rn | awk -F: '!seen[$1]++ && $1!=""' | cut -d: -f1)

echo "{"
echo "  \"active\": \"$active_wifi\","
echo "  \"networks\": ["

first=true
while read -r ssid; do
    if [ -z "$ssid" ]; then continue; fi
    if echo "$known_networks" | grep -Fqx "$ssid"; then
        known="true"
    else
        known="false"
    fi

    if [ "$first" = true ]; then
        first=false
    else
        echo ","
    fi
    safe_ssid=$(echo "$ssid" | sed 's/"/\\"/g')
    echo -n "    { \"ssid\": \"$safe_ssid\", \"known\": $known }"
done <<< "$wifi_list"

echo ""
echo "  ]"
echo "}"
echo "END_JSON"