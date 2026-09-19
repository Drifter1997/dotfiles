#!/usr/bin/env bash

# Terminate any existing swayidle instances
pkill -x swayidle 2>/dev/null

# Start swayidle with 2-minute (120s) inactivity timeout
exec swayidle -w \
    timeout 120 'if [ ! -f /tmp/sway_idle_inhibited ]; then swaylock -f -c 000000; fi' \
    timeout 600 'if [ ! -f /tmp/sway_idle_inhibited ]; then swaymsg "output * power off"; fi' resume 'swaymsg "output * power on"' \
    before-sleep 'swaylock -f -c 000000' \
    lock 'swaylock -f -c 000000'
