ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base

RUN  \
    apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y --no-install-recommends stuntman-server && \
    apt-cleanup

COPY rootfs/ /
RUN chmod a+x /run.sh

EXPOSE 3478/tcp 3478/udp

# USER nobody

ENTRYPOINT ["/run.sh"]

