ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base-java

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y openssh-server rsync &&\
	apt-cleanup

RUN \
    mkdir -p /run/sshd && \
    mkdir -p /var/run/sshd

COPY rootfs/ /
RUN chmod 644 /root/.ssh/authorized_keys

VOLUME /recordings
