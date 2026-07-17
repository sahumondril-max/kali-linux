#!/bin/bash

export DISPLAY=:1
export HOME=/root

# Start virtual display
Xvfb :1 -screen 0 1280x720x24 &
sleep 2

# Start D-Bus
mkdir -p /run/dbus
dbus-daemon --system &
sleep 2

# Start XFCE
startxfce4 &
sleep 5

# Start VNC server
x11vnc \
-display :1 \
-forever \
-shared \
-nopw \
-bg

# Railway port
PORT=${PORT:-8080}

exec websockify \
--web=/usr/share/novnc \
$PORT \
localhost:5900