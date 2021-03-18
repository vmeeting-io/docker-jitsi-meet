FROM lovasoa/wbo:1.9.1
USER root

ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/s6-overlay.tar.gz
ADD https://github.com/subchen/frep/releases/download/v1.3.5/frep-1.3.5-linux-amd64 /usr/bin/frep

COPY rootfs/ /

RUN \
	tar xfz /tmp/s6-overlay.tar.gz -C / && \
	rm -f /tmp/*.tar.gz && \
  chmod +x /usr/bin/frep

ENTRYPOINT []
EXPOSE 9002

CMD PORT=9002 npm start
