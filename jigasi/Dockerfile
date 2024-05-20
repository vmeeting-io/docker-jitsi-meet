ARG JITSI_REPO=theun
ARG VMEETING_TAG
FROM ${JITSI_REPO}/base-java:${VMEETING_TAG}

LABEL org.opencontainers.image.title="Jitsi Gateway to SIP (jigasi)"
LABEL org.opencontainers.image.description="Server-side application that allows regular SIP clients to join conferences."
LABEL org.opencontainers.image.url="https://github.com/jitsi/jigasi"
LABEL org.opencontainers.image.source="https://github.com/jitsi/docker-jitsi-meet"
LABEL org.opencontainers.image.documentation="https://jitsi.github.io/handbook/"

ENV GOOGLE_APPLICATION_CREDENTIALS /config/key.json
ENV JIGASI_VERSION=1.1-329-g04ad08f-1

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y jigasi=${JIGASI_VERSION} jq && \
	apt-cleanup

COPY rootfs/ /

RUN chmod 755 /wait-for-it.sh

VOLUME ["/config", "/tmp/transcripts"]
