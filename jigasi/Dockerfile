ARG JITSI_REPO=theun
ARG VMEETING_TAG
FROM ${JITSI_REPO}/base-java:${VMEETING_TAG}

ENV GOOGLE_APPLICATION_CREDENTIALS /config/key.json
ENV JIGASI_VERSION=1.1-126-g6df3db2-1

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y jigasi=${JIGASI_VERSION} jq && \
	apt-cleanup

COPY rootfs/ /

VOLUME ["/config", "/tmp/transcripts"]
