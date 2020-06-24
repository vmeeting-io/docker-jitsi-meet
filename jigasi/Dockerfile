ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base-java

ENV GOOGLE_APPLICATION_CREDENTIALS /config/key.json

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y jigasi jq && \
	apt-cleanup

COPY rootfs/ /

VOLUME ["/config", "/tmp/transcripts"]
