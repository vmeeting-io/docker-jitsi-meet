ARG JITSI_REPO=jitsi
FROM grafana/grafana:7.2.1

# sudo 설치 및 grafana 사용자에게 sudo 권한 부여
USER root
RUN apk --no-cache add sudo && \
    echo "grafana ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

COPY /rootfs/ /

RUN apk --no-cache add curl
RUN chmod a+x /entrypoint.sh
RUN chown -R grafana /etc/grafana/provisioning/jitsi

# grafana 사용자로 실행 (sudo 권한 보유)
USER grafana
ENTRYPOINT [ "/entrypoint.sh" ]
