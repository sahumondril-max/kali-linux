# ============================================================
#  Kali Linux Desktop via noVNC — Railway.app ready
#  Access via browser: https://<your-app>.railway.app/vnc.html
# ============================================================
FROM kalilinux/kali-rolling:latest

# ── Build args / env ─────────────────────────────────────────
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=UTC \
    VNC_PORT=5900 \
    NOVNC_PORT=8080 \
    VNC_RESOLUTION=1920x1080 \
    VNC_DEPTH=24 \
    VNC_PASSWORD=kalilinux \
    USER=kali \
    HOME=/home/kali \
    DISPLAY=:1

# ── System update & core packages ───────────────────────────
RUN apt-get update -y && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        kali-desktop-xfce \
        xfce4 \
        xfce4-goodies \
        dbus-x11 \
        tigervnc-standalone-server \
        tigervnc-common \
        novnc \
        websockify \
        python3 \
        python3-pip \
        python3-numpy \
        sudo \
        curl \
        wget \
        git \
        vim \
        nano \
        net-tools \
        iproute2 \
        iputils-ping \
        procps \
        htop \
        firefox-esr \
        fonts-noto \
        fonts-noto-color-emoji \
        adwaita-icon-theme \
        pulseaudio \
        xdg-utils \
        x11-xserver-utils \
        xauth \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ── Create non-root user ─────────────────────────────────────
RUN useradd -m -s /bin/bash -G sudo kali 2>/dev/null || true && \
    echo "kali:kali" | chpasswd && \
    echo "kali ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# ── Configure VNC password ───────────────────────────────────
RUN mkdir -p /home/kali/.vnc && \
    printf '%s\n%s\n\n' "kalilinux" "kalilinux" | vncpasswd /home/kali/.vnc/passwd && \
    chmod 600 /home/kali/.vnc/passwd && \
    chown -R kali:kali /home/kali/.vnc

# ── XFCE startup script for VNC ─────────────────────────────
RUN printf '%s\n' \
    '#!/bin/bash' \
    'unset SESSION_MANAGER' \
    'unset DBUS_SESSION_BUS_ADDRESS' \
    'export XKL_XMODMAP_DISABLE=1' \
    '' \
    'if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then' \
    '    eval $(dbus-launch --sh-syntax --exit-with-session)' \
    'fi' \
    '' \
    'exec startxfce4' \
    > /home/kali/.vnc/xstartup
RUN chmod +x /home/kali/.vnc/xstartup && \
    chown kali:kali /home/kali/.vnc/xstartup

# ── noVNC index symlink ──────────────────────────────────────
RUN ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html 2>/dev/null || true

# ── Copy startup script ──────────────────────────────────────
COPY start.sh /start.sh
RUN chmod +x /start.sh

# ── Fix ownership ────────────────────────────────────────────
RUN chown -R kali:kali /home/kali

EXPOSE 8080

CMD ["/start.sh"]
