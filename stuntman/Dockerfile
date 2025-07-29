ARG JITSI_REPO=theun
FROM docker.io/library/debian:bookworm-slim

# ARG VMEETING_USER_GID=1001
# ARG VMEETING_USER_UID=1001

# RUN \
#     groupadd --gid "$VMEETING_USER_GID" vmeeting &&\
#     useradd --uid "$VMEETING_USER_UID" --gid vmeeting --shell /bin/bash --home /home/vmeeting --no-create-home vmeeting &&\
#     mkdir /home/vmeeting &&\
#     chown vmeeting: /home/vmeeting

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
# USER vmeeting
ENTRYPOINT ["/run.sh"]