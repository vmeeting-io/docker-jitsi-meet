ARG JITSI_REPO=jitsi
FROM grafana/grafana:7.2.1

COPY /rootfs/ /

USER root
RUN apk --no-cache add curl
RUN chmod a+x /entrypoint.sh
RUN chown -R grafana /etc/grafana/provisioning/jitsi

USER grafana
ENTRYPOINT [ "/entrypoint.sh" ]
