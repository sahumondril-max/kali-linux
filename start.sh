#!/bin/bash
# ============================================================
#  start.sh — entrypoint for Kali noVNC on Railway.app
# ============================================================
set -e

# ── Railway dynamically assigns $PORT, default to 8080 ──────
PORT="${PORT:-8080}"
VNC_PORT="${VNC_PORT:-5900}"
VNC_DISPLAY=":1"
VNC_RESOLUTION="${VNC_RESOLUTION:-1920x1080}"
VNC_DEPTH="${VNC_DEPTH:-24}"
VNC_PASSWORD="${VNC_PASSWORD:-kalilinux}"
NOVNC_PATH="/usr/share/novnc"
WEBSOCKIFY_PATH="/usr/bin/websockify"

echo "============================================="
echo "  Kali Linux noVNC Desktop"
echo "  noVNC  → http://0.0.0.0:${PORT}"
echo "  VNC    → localhost:${VNC_PORT}"
echo "  Res    → ${VNC_RESOLUTION}x${VNC_DEPTH}bpp"
echo "============================================="

# ── Ensure home & VNC dirs exist with correct perms ─────────
mkdir -p /home/kali/.vnc /home/kali/.config/xfce4
chown -R kali:kali /home/kali

# ── Write VNC password file ──────────────────────────────────
echo "Setting VNC password..."
printf '%s\n%s\n\n' "${VNC_PASSWORD}" "${VNC_PASSWORD}" | \
    su -c "vncpasswd /home/kali/.vnc/passwd" kali || \
    printf "${VNC_PASSWORD}\n${VNC_PASSWORD}\n\n" | vncpasswd /home/kali/.vnc/passwd

chmod 600 /home/kali/.vnc/passwd
chown kali:kali /home/kali/.vnc/passwd

# ── Write xstartup (always fresh) ───────────────────────────
cat > /home/kali/.vnc/xstartup << 'XSTARTUP'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XKL_XMODMAP_DISABLE=1
export LIBGL_ALWAYS_SOFTWARE=1

# D-Bus session
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax --exit-with-session)
fi

# Polkit agent (background)
/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1 &
xfce4-session
XSTARTUP
chmod +x /home/kali/.vnc/xstartup
chown kali:kali /home/kali/.vnc/xstartup

# ── Clean stale VNC locks ────────────────────────────────────
echo "Cleaning stale VNC locks..."
rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null || true

# ── Start TigerVNC server ────────────────────────────────────
echo "Starting VNC server on display ${VNC_DISPLAY} (${VNC_RESOLUTION})..."
su -c "vncserver ${VNC_DISPLAY} \
    -geometry ${VNC_RESOLUTION} \
    -depth ${VNC_DEPTH} \
    -rfbport ${VNC_PORT} \
    -SecurityTypes VncAuth \
    -fg &" kali

# Wait for VNC to initialise
sleep 3

# Verify VNC started
if ! pgrep -x "Xtigervnc" > /dev/null && ! pgrep -x "Xvnc" > /dev/null; then
    echo "⚠  VNC server failed to start. Attempting fallback launch..."
    su -c "vncserver ${VNC_DISPLAY} -geometry ${VNC_RESOLUTION} -depth ${VNC_DEPTH} -rfbport ${VNC_PORT} -localhost no -SecurityTypes None &" kali
    sleep 3
fi

echo "VNC server running."

# ── Find websockify ──────────────────────────────────────────
if ! command -v websockify &>/dev/null; then
    WEBSOCKIFY_PATH="$(python3 -m websockify --help &>/dev/null && echo 'python3 -m websockify' || echo '/usr/bin/websockify')"
fi

# ── Start noVNC / websockify ─────────────────────────────────
echo "Starting noVNC on 0.0.0.0:${PORT} → localhost:${VNC_PORT}..."
websockify \
    --web="${NOVNC_PATH}" \
    --heartbeat=30 \
    "0.0.0.0:${PORT}" \
    "localhost:${VNC_PORT}" &

WEBSOCKIFY_PID=$!
echo "websockify PID: ${WEBSOCKIFY_PID}"

# ── Trap SIGTERM/SIGINT for graceful shutdown ────────────────
cleanup() {
    echo "Shutting down..."
    kill $WEBSOCKIFY_PID 2>/dev/null || true
    su -c "vncserver -kill ${VNC_DISPLAY}" kali 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

# ── Keep container alive & watch for crashes ─────────────────
echo ""
echo "✓ Kali Desktop is ready!"
echo "  Open: http://<your-railway-domain>/vnc.html"
echo "  Password: ${VNC_PASSWORD}"
echo ""

while true; do
    # Restart websockify if it dies
    if ! kill -0 $WEBSOCKIFY_PID 2>/dev/null; then
        echo "websockify crashed — restarting..."
        websockify \
            --web="${NOVNC_PATH}" \
            --heartbeat=30 \
            "0.0.0.0:${PORT}" \
            "localhost:${VNC_PORT}" &
        WEBSOCKIFY_PID=$!
    fi

    # Restart VNC if it dies
    if ! pgrep -x "Xtigervnc" > /dev/null && ! pgrep -x "Xvnc" > /dev/null; then
        echo "VNC server crashed — restarting..."
        rm -f /tmp/.X*-lock /tmp/.X11-unix/X* 2>/dev/null || true
        su -c "vncserver ${VNC_DISPLAY} -geometry ${VNC_RESOLUTION} -depth ${VNC_DEPTH} -rfbport ${VNC_PORT} -SecurityTypes VncAuth -fg &" kali
        sleep 3
    fi

    sleep 10
done
