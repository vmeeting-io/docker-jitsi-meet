ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/s6-overlay.tar.gz
ADD https://github.com/subchen/frep/releases/download/v1.3.5/frep-1.3.5-linux-amd64 /usr/bin/frep

COPY rootfs/ /

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y vim curl

RUN \
	tar xfz /tmp/s6-overlay.tar.gz -C / && \
	rm -f /tmp/*.tar.gz && \
  chmod +x /usr/bin/frep

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs git

WORKDIR /wbo/whitebophir
COPY whitebophir/package*.json ./
RUN npm install

COPY whitebophir/ /wbo/whitebophir/

ENTRYPOINT []
EXPOSE 9002

VOLUME /wbo/whitebophir/server-data