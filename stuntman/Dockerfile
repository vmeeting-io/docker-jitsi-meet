ARG JITSI_REPO=theun
FROM debian:stretch-slim

RUN  \
    apt-get update && \
    apt-get install -y stuntman-server && \
    apt-get clean

COPY rootfs/ /
RUN chmod a+x /run.sh

EXPOSE 3478/tcp 3478/udp

# USER nobody

ENTRYPOINT ["/run.sh"]

