ARG JITSI_REPO=theun
ARG VMEETING_TAG
ARG VMEETING_FRONT_BASE
ARG VMEETING_API_BASE
ARG JWT_APP_ID
FROM ${JITSI_REPO}/base

COPY rootfs/ /

ENV PATH=/web/jitsi-meet/node_modules/.bin:$PATH

WORKDIR /web/jitsi-meet

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y nodejs git make vim inotify-tools && \
	apt-cleanup && \
	rm -rf /tmp/pkg /var/cache/apt

RUN echo "set encoding=utf-8" >> /etc/vim/vimrc

# lib-jitsi-meet (dev HMR / local linking)
COPY lib-jitsi-meet/ /web/lib-jitsi-meet/
RUN cd /web/lib-jitsi-meet/ && npm install

COPY jitsi-meet/package*.json ./
RUN npm install --legacy-peer-deps

COPY jitsi-meet/ /web/jitsi-meet/
RUN cp -f /web/jitsi-meet/interface_config*.js /defaults && \
	cp -f /web/jitsi-meet/config*.js /defaults && \
	cp -f /web/jitsi-meet/title*.html /defaults && \
	chmod 755 /wait-for-it.sh && \
	make all

ENTRYPOINT []

EXPOSE 8080 8088

VOLUME ["/config", "/usr/share/jitsi-meet/transcripts"]
