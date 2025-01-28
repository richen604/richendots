#!/usr/bin/env bash

# Check if the win11 VM is running
if ! sudo virsh list --state-running --name | grep -q "win11"; then
    echo "The win11 VM is not running. Please start it before connecting via RDP."
    exit 1
fi

# Prompt for password and hide input
read -sp "Enter password: " password
echo  # Add a newline after password input

# Check if RDP is running
if ! pgrep -f "xfreerdp" > /dev/null; then
    echo "RDP is not running. Starting RDP..."
    nohup xfreerdp \
        /v:10.0.0.172 \
        /u:richard \
        /p:"$password" \
        +dynamic-resolution \
        /gfx:avc444 \
        /network:auto \
        /compression-level:2 \
        /sound \
        /microphone \
        +clipboard \
        +fonts \
        +aero \
        +window-drag \
        +menu-anims \
        +themes \
        /cert:ignore > /dev/null 2>&1 &
    echo "RDP started in the background."
else
    echo "RDP is already running."
fi
