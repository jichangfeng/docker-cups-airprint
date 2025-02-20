#!/bin/bash -e

echo -e "${ADMIN_PASSWORD}\n${ADMIN_PASSWORD}" | passwd admin

if [ ! -f /etc/cups/cupsd.conf ]; then
  cp -rpn /etc/cups-skel/* /etc/cups/
fi

# Start dbus and avahi
if [ -f /run/dbus/pid ]; then
    rm -f /run/dbus/pid
fi
dbus-daemon --system
if [ -f /run/avahi-daemon/pid ]; then
    rm -f /run/avahi-daemon/pid
fi
avahi-daemon -D

# Start automatic airprint refresh for avahi
/usr/local/bin/avahi-airprint-refresh.sh &

exec "$@"
