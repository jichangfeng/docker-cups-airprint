FROM debian:stable
MAINTAINER Changfeng Ji <jichf@qq.com>

# environment
ENV ADMIN_PASSWORD=admin

# install packages
RUN apt update \
&& apt install -y \
  sudo \
  whois \
  inetutils-ping \
  usbutils \
  cups \
  cups-client \
  cups-bsd \
  cups-filters \
  foomatic-db-compressed-ppds \
  printer-driver-all \
  openprinting-ppds \
  hpijs-ppds \
  hp-ppd \
  hplip \
  smbclient \
  printer-driver-cups-pdf \
  avahi-daemon \
  avahi-discover \
  inotify-tools \
&& apt clean \
&& rm -rf /var/lib/apt/lists/*

RUN useradd \
  --groups=sudo,lp,lpadmin \
  --create-home \
  --home-dir=/home/admin \
  --shell=/bin/bash \
  --password=$(mkpasswd $ADMIN_PASSWORD) \
  admin \
&& sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

# enable access to CUPS
RUN cp /etc/cups/cupsd.conf /etc/cups/cupsd.conf.bak
RUN /usr/sbin/cupsd \
  && while [ ! -f /var/run/cups/cupsd.pid ]; do sleep 1; done \
  && cupsctl --remote-admin --remote-any --share-printers \
  && kill $(cat /var/run/cups/cupsd.pid)
RUN echo "ServerAlias *" >> /etc/cups/cupsd.conf

# copy /etc/cups for skeleton usage
RUN cp -rp /etc/cups /etc/cups-skel

# airprint generate
RUN apt update && apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-libxml2 \
    libcups2-dev \
&& apt clean \
&& rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /root/airprint-generate
RUN /root/airprint-generate/bin/pip install pycups==2.0.1
RUN wget https://raw.githubusercontent.com/tjfontaine/airprint-generate/master/airprint-generate.py -O /root/airprint-generate.py
RUN chmod +x /root/airprint-generate.py

# expose IPP printer sharing
EXPOSE 631/tcp

# expose avahi advertisement
EXPOSE 5353/udp

# volumes
VOLUME ["/etc/cups"]

# avahi airprint refresh
ADD avahi-airprint-refresh.sh /usr/local/bin/avahi-airprint-refresh.sh
RUN chmod +x /usr/local/bin/avahi-airprint-refresh.sh

# entrypoint
ADD docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]

# default command
CMD ["cupsd", "-f"]
