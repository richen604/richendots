#!/usr/bin/env bash

# Check if the win11 VM is running
if ! sudo virsh list --state-running --name | grep -q "win11"; then
    echo "The win11 VM is not running. Please start it before connecting via looking glass."
    exit 1
fi

# Launch looking-glass-client with F10 as the mouse capture key
nohup looking-glass-client -f /dev/kvmfr0 -m 59 >/dev/null 2>&1 &
