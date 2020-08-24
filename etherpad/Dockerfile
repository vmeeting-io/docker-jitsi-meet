FROM etherpad/etherpad:1.8.4

ARG ETHERPAD_PLUGINS="ep_whiteboard"

RUN for PLUGIN_NAME in ${ETHERPAD_PLUGINS}; do npm install "${PLUGIN_NAME}" || exit 1; done

ADD ./rootfs/defaults/settings.json /opt/etherpad-lite/settings.json

EXPOSE 9001
