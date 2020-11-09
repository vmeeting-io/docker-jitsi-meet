FROM etherpad/etherpad:1.8.4
USER root

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2

ARG FREP_VERSION=1.3.11

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/s6-overlay.tar.gz
ADD https://github.com/subchen/frep/releases/download/v$FREP_VERSION/frep-$FREP_VERSION-linux-amd64 /usr/bin/frep

COPY rootfs/ /

ARG ETHERPAD_PLUGINS="ep_whiteboard"

RUN for PLUGIN_NAME in ${ETHERPAD_PLUGINS}; do npm install "${PLUGIN_NAME}" || exit 1; done
RUN \
	tar xfz /tmp/s6-overlay.tar.gz -C / && \
	rm -f /tmp/*.tar.gz && \
  chmod +x /usr/bin/frep

ENTRYPOINT []
EXPOSE 9001
