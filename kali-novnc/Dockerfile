FROM kalilinux/kali-rolling

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    xfce4 \
    xfce4-terminal \
    x11vnc \
    xvfb \
    novnc \
    websockify \
    supervisor \
    dbus-x11 \
    firefox-esr \
    wget \
    curl \
    && apt clean

RUN mkdir -p /root/.vnc

COPY start.sh /start.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN chmod +x /start.sh

EXPOSE 8080

CMD ["/start.sh"]