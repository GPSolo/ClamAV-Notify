#!/bin/bash

USER_NAME="$(whoami)"
USER_ID=$(id -u "$USER_NAME")
DBUS_SESSION="unix:path=/run/user/${USER_ID}/bus"

journalctl -fu clamav-clamonacc | while read -r line; do
    if echo "$line" | grep -q "FOUND"; then
        # Strip systemd prefix to get: "/tmp/file.com: Eicar-Test-Signature FOUND"
        ENTRY=$(echo "$line" | awk -F']: ' '{print $2}')
        FILE=$(echo "$ENTRY" | awk -F': ' '{print $1}')
        THREAT=$(echo "$ENTRY" | awk -F': ' '{print $2}' | sed 's/ FOUND//')

        sudo -u "$USER_NAME" \
            DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION" \
            notify-send \
            --urgency=critical \
            "🛡️ Threat Detected by ClamAV" \
            "File: $FILE\nThreat: $THREAT"
    fi
done

