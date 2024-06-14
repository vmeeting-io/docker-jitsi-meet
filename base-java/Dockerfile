ARG JITSI_REPO=theun
ARG VMEETING_TAG
FROM ${JITSI_REPO}/base:${VMEETING_TAG}

RUN	\
	mkdir -p /usr/share/man/man1 && \
    apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y nodejs openjdk-17-jre-headless openjdk-17-jdk-headless && \
    apt-cleanup
