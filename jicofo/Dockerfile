# syntax=docker/dockerfile:1.2

ARG JITSI_REPO=theun
ARG VMEETING_TAG
FROM ${JITSI_REPO}/base-java as builder

RUN \
    cd /opt/ && \
    wget -q https://archive.apache.org/dist/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz && \
    tar -xvzf apache-maven-3.5.4-bin.tar.gz && \
    mv apache-maven-3.5.4 maven
ENV M2_HOME=/opt/maven
ENV PATH=${M2_HOME}/bin:${PATH}

COPY jicofo /jicofo

WORKDIR /jicofo
RUN --mount=type=cache,target=/root/.m2 mvn clean package -P buildFatJar

ARG VMEETING_TAG
FROM ${JITSI_REPO}/base-java

ARG JICOFO_VERSION=1.0-1075-1

RUN apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y rubygems && \
    gem install hocon && \
    apt-dpkg-wrap apt-get install -y --no-install-recommends dirmngr wget iputils-ping snmp procps lm-sensors jicofo=${JICOFO_VERSION} && \
    rm -rf /var/lib/apt/lists/*

# Telegrapf
RUN set -ex && \
    for key in \
        9D539D90D3328DC7D6C8D3B9D8FF8E1F7DF8B07E ; \
    do \
        gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys "$key" ; \
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

RUN chmod 755 /wait-for-it.sh

# COPY --from=builder /jicofo/target/jicofo-1.1-SNAPSHOT.jar /usr/share/jicofo/jicofo.jar
COPY --from=builder /jicofo/jicofo/target/jicofo-1.1-SNAPSHOT-jar-with-dependencies.jar /usr/share/jicofo/jicofo.jar

VOLUME /config

