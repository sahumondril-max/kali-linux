#!/bin/bash

Xvfb :1 -screen 0 1280x720x24 &
export DISPLAY=:1

startxfce4 &

x11vnc \
-display :1 \
-forever \
-nopw \
-shared &

websockify \
--web=/usr/share/novnc/ \
8080 \
localhost:5900