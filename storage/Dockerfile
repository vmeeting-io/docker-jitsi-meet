FROM debian:stretch-slim

ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.1/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /

RUN \
	apt-get update && \
	apt-get install -y openssh-server rsync curl &&\
	apt-get clean


RUN \
	apt-get update && \
	apt-get install -y libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x && \
	apt-get clean

RUN \
    mkdir -p /run/sshd && \
    mkdir -p /var/run/sshd

COPY rootfs/ /

VOLUME ["/recordings"]

ENTRYPOINT ["/init"]
