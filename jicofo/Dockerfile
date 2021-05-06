ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base-java

# COPY jicofo_1.0-664-1_all.deb /

# RUN \
#     apt install -y /jicofo_1.0-664-1_all.deb && \
#     rm /jicofo_1.0-664-1_all.deb

# Telegrapf
RUN apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y rubygems && \
    gem install hocon && \
    apt-dpkg-wrap apt-get install -y --no-install-recommends dirmngr wget iputils-ping snmp procps lm-sensors jicofo=1.0-690-1 && \
    rm -rf /var/lib/apt/lists/*

RUN set -ex && \
    for key in \
        05CE15085FC09D18E99EFB22684A14CF2582E0C5 ; \
    do \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
        gpg --keyserver pgp.mit.edu --recv-keys "$key" || \
        gpg --keyserver keyserver.pgp.com --recv-keys "$key" ; \
    done

ENV TELEGRAF_VERSION 1.14.4
ENV ARCH='amd64'
RUN \
    wget --no-verbose https://dl.influxdata.com/telegraf/releases/telegraf_${TELEGRAF_VERSION}-1_${ARCH}.deb.asc && \
    wget --no-verbose https://dl.influxdata.com/telegraf/releases/telegraf_${TELEGRAF_VERSION}-1_${ARCH}.deb && \
    gpg --batch --verify telegraf_${TELEGRAF_VERSION}-1_${ARCH}.deb.asc telegraf_${TELEGRAF_VERSION}-1_${ARCH}.deb && \
    dpkg -i telegraf_${TELEGRAF_VERSION}-1_${ARCH}.deb && \
    rm -f telegraf_${TELEGRAF_VERSION}-1_${ARCH}.deb*

COPY rootfs/ /

VOLUME /config

