ARG JITSI_REPO=theun
FROM debian:bullseye-slim

RUN apt-get update && \
	apt-get install -y wget g++ make libboost-dev libssl-dev

RUN cd / && \
    wget -q https://www.stunprotocol.org/stunserver-1.2.16.tgz && \
    tar -xvzf stunserver-1.2.16.tgz

RUN cd /stunserver && make

COPY rootfs/ /
RUN chmod a+x /run.sh

EXPOSE 3478/tcp 3478/udp

# USER nobody

ENTRYPOINT ["/run.sh"]

