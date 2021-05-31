ARG JITSI_REPO=theun

FROM ${JITSI_REPO}/base as builder
RUN	\
	mkdir -p /usr/share/man/man1 && \
	wget -q https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public -O /etc/apt/trusted.gpg.d/openjdk.asc && \
	echo "deb https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ buster main" > /etc/apt/sources.list.d/openjdk.list && \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y adoptopenjdk-8-hotspot && \
	apt-cleanup

RUN \
    cd /opt/ && \
    wget -q http://apache.mirrors.pair.com/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz && \
    tar -xvzf apache-maven-3.5.4-bin.tar.gz && \
    mv apache-maven-3.5.4 maven
ENV M2_HOME=/opt/maven
ENV PATH=${M2_HOME}/bin:${PATH}

COPY jitsi-videobridge /jitsi-videobridge

RUN cd /jitsi-videobridge && \
    mvn clean package -am -pl jvb


FROM ${JITSI_REPO}/base-java

ENV VIDEOBRIDGE_VERSION=2.1-376-g9f12bfe2-1

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

# gstreamer
RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x gstreamer1.0-gl && \
	apt-cleanup


EXPOSE 8125/udp 8092/udp 8094 9090

COPY rootfs/ /

COPY --from=builder /jitsi-videobridge/jvb/target/jitsi-videobridge-2.1-SNAPSHOT.jar /usr/share/jitsi-videobridge/jitsi-videobridge.jar
RUN rm -f /usr/share/jitsi-videobridge/lib/jitsi-media-transform*.jar
COPY --from=builder /jitsi-videobridge/jitsi-media-transform/target/jitsi-media-transform-2.1-SNAPSHOT.jar /usr/share/jitsi-videobridge/lib/jitsi-media-transform.jar

VOLUME /config
