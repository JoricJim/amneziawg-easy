FROM ubuntu:noble
ARG DEBIAN_FRONTEND=noninteractive
RUN sed -i 's/^Types: deb$/Types: deb deb-src/' /etc/apt/sources.list.d/ubuntu.sources
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get install -y git software-properties-common python3-launchpadlib gnupg2 linux-headers-$(uname -r) zstd sudo
RUN add-apt-repository ppa:amnezia/ppa
RUN apt-get -y update
RUN apt-get -y upgrade
RUN echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/00-amnezia.conf
RUN echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf
RUN echo net.ipv4.conf.all.src_valid_mark=1 >> /etc/sysctl.conf
RUN sysctl -p
RUN mkdir /app
RUN cd /app
RUN cd /app && git clone https://github.com/amnezia-vpn/amneziawg-tools.git
RUN apt-get install -y make g++ gcc
RUN cd /app/amneziawg-tools/src && make && make install
RUN ln -s /app/amneziawg-tools/src/wg /usr/bin/
RUN ln -s /app/amneziawg-tools/src/wg-quick/wg-quick /usr/bin/
RUN cd /app && git clone https://github.com/wg-easy/wg-easy.git && cd /app/wg-easy/ && git checkout production && cp -r /app/wg-easy/src/. /app/
RUN apt-get install -y curl unzip zip

WORKDIR /app

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash - && apt-get install -y nodejs 
RUN npm install -g npm@latest
RUN npm ci --omit=dev &&\
    cp -r node_modules /node_modules

HEALTHCHECK CMD /usr/bin/timeout 5s /bin/sh -c "/usr/bin/wg show | /bin/grep -q interface || exit 1" --interval=1m --timeout=5s --retries=3

RUN cp /app/wgpw.sh /bin/wgpw
RUN chmod +x /bin/wgpw
RUN apt-get install -y \
    dpkg \
    dumb-init \
    iptables \
    iproute2
RUN update-alternatives --install /sbin/iptables iptables /sbin/iptables-legacy 10 --slave /sbin/iptables-restore iptables-restore /sbin/iptables-legacy-restore --slave /sbin/iptables-save iptables-save /sbin/iptables-legacy-save
ENV DEBUG=Server,WireGuard
ENV WG_PATH=/etc/amnezia/amneziawg/
RUN rm -f /usr/bin/wg-quick
RUN ln -s /usr/bin/awg-quick /usr/bin/wg-quick

EXPOSE 51621
EXPOSE 51620

ENV WG_HOST=194.87.243.114
ENV LANGUAGE=ru
ENV PORT=51621
ENV WG_DEVICE=eth0
ENV WG_PORT=51620
ENV WG_CONFIG_PORT=51620
ENV WG_DEFAULT_DNS=1.1.1.1
ENV WG_ALLOWED_IPS=0.0.0.0/0, ::/0
ENV DICEBEAR_TYPE=croodles
ENV UI_TRAFFIC_STATS=true
ENV UI_CHART_TYPE=1
ENV ENABLE_PROMETHEUS_METRICS=true
ENV MAX_AGE=1440
ENV WG_ENABLE_ONE_TIME_LINKS=true

