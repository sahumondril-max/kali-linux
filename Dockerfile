FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    xfce4 \
    xfce4-session \
    xfce4-terminal \
    xfwm4 \
    dbus \
    dbus-x11 \
    xauth \
    x11vnc \
    xvfb \
    novnc \
    websockify \
    supervisor \
    firefox-esr \
    && apt clean

RUN mkdir -p /root/.vnc

COPY start.sh /start.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /start.sh

EXPOSE 8080

CMD ["/start.sh"]