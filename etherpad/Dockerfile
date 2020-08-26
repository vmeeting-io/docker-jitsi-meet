FROM etherpad/etherpad:1.8.4
USER root

ADD https://github.com/subchen/frep/releases/download/v1.3.5/frep-1.3.5-linux-amd64 /usr/bin/frep

COPY rootfs/ /

ARG ETHERPAD_PLUGINS="ep_whiteboard"

RUN for PLUGIN_NAME in ${ETHERPAD_PLUGINS}; do npm install "${PLUGIN_NAME}" || exit 1; done
RUN chmod +x /usr/bin/frep

ENTRYPOINT [ "/etc/cont-init.d/10-config" ]
EXPOSE 9001
