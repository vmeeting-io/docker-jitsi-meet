# syntax=docker/dockerfile:1.2

ARG JITSI_REPO=theun
ARG VMEETING_TAG
FROM ${JITSI_REPO}/base:${VMEETING_TAG} as builder
RUN	\
	mkdir -p /usr/share/man/man1 && \
    apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y openjdk-11-jre-headless && \
    apt-cleanup

RUN \
    cd /opt/ && \
    wget -q https://archive.apache.org/dist/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz && \
    tar -xvzf apache-maven-3.5.4-bin.tar.gz && \
    mv apache-maven-3.5.4 maven
ENV M2_HOME=/opt/maven
ENV PATH=${M2_HOME}/bin:${PATH}

COPY jitsi-videobridge /jitsi-videobridge

WORKDIR /jitsi-videobridge
RUN --mount=type=cache,target=/root/.m2 mvn clean package -P buildFatJar
RUN ls -lha /jitsi-videobridge/jvb/target

ARG VMEETING_TAG
FROM ${JITSI_REPO}/base-java:${VMEETING_TAG}

ENV VIDEOBRIDGE_VERSION=2.1-551-g2ad6eb0b-1

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y jitsi-videobridge2=${VIDEOBRIDGE_VERSION} jq curl iproute2 dnsutils libpcap-dev openssh-server rsync && \
	apt-cleanup


# Telegrapf
RUN apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y --no-install-recommends dirmngr wget iputils-ping snmp procps lm-sensors && \
    rm -rf /var/lib/apt/lists/*

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

EXPOSE 8125/udp 8092/udp 8094 9090

COPY rootfs/ /

RUN chmod 755 /wait-for-it.sh

COPY --from=builder /jitsi-videobridge/jvb/target/jitsi-videobridge-2.1-SNAPSHOT-jar-with-dependencies.jar /usr/share/jitsi-videobridge/jitsi-videobridge.jar

VOLUME /config
