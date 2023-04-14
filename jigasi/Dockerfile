ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base-java

ENV GOOGLE_APPLICATION_CREDENTIALS /config/key.json
ENV JIGASI_VERSION=1.1-265-g4049f97-1

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y jigasi=${JIGASI_VERSION} jq && \
	apt-cleanup

COPY rootfs/ /

VOLUME ["/config", "/tmp/transcripts"]
