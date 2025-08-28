ARG JITSI_REPO=theun
FROM docker.io/library/debian:bookworm-slim

# vmeeting 사용자 생성 및 sudo 권한 부여
ARG VMEETING_USER_GID=1001
ARG VMEETING_USER_UID=1001

RUN \
    groupadd --gid "$VMEETING_USER_GID" vmeeting &&\
    useradd --uid "$VMEETING_USER_UID" --gid vmeeting --shell /bin/bash --home /home/vmeeting --no-create-home vmeeting &&\
    mkdir /home/vmeeting &&\
    chown vmeeting: /home/vmeeting &&\
    apt-get update && \
    apt-get install -y sudo && \
    echo "vmeeting ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
	apt-get install -y wget g++ make libboost-dev libssl-dev

RUN cd / && \
    wget -q https://www.stunprotocol.org/stunserver-1.2.16.tgz && \
    tar -xvzf stunserver-1.2.16.tgz

RUN cd /stunserver && make

COPY rootfs/ /
RUN chmod a+x /run.sh

EXPOSE 3478/tcp 3478/udp

# vmeeting 사용자로 실행 (sudo 권한 보유)
USER vmeeting
ENTRYPOINT ["/run.sh"]