ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base-java

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y openssh-server rsync curl &&\
	apt-cleanup

RUN \
    mkdir -p /run/sshd && \
    mkdir -p /var/run/sshd

COPY rootfs/ /

VOLUME /recordings
