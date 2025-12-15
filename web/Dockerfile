ARG JITSI_REPO=theun
ARG VMEETING_TAG
FROM ${JITSI_REPO}/base

COPY rootfs/ /

# ENV JITSI_MEET_WEB_VERSION=1.0.4466-1
# ENV JITSI_MEET_WEB_CONFIG_VERSION=1.0.4466-1
ENV JITSI_MEET_WEB_VERSION=1.0.4289-1
ENV JITSI_MEET_WEB_CONFIG_VERSION=1.0.4289-1

RUN \
	apt-dpkg-wrap apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62 && \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y --allow-unauthenticated vim curl make apache2-utils jitsi-meet-web=${JITSI_MEET_WEB_VERSION} && \
	apt-dpkg-wrap apt-get -d install -y --allow-unauthenticated jitsi-meet-web-config=${JITSI_MEET_WEB_CONFIG_VERSION} && \
    dpkg -x /var/cache/apt/archives/jitsi-meet-web-config*.deb /tmp/pkg && \
    mv /tmp/pkg/usr/share/jitsi-meet-web-config/config.js /defaults && \
	mv /usr/share/jitsi-meet/interface_config.js /defaults && \
	apt-cleanup && \
	rm -rf /tmp/pkg /var/cache/apt

RUN echo "set encoding=utf-8" >> /etc/vim/vimrc

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
	apt-get install -y nodejs git && \
	npm install -g serve
	# npm install -g http-server

WORKDIR /web/jitsi-meet
COPY jitsi-meet/package*.json ./
RUN npm install --legacy-peer-deps

COPY jitsi-meet/ /web/jitsi-meet/
RUN cp -f /web/jitsi-meet/interface_config*.js /defaults
RUN cp -f /web/jitsi-meet/config*.js /defaults
RUN cp -f /web/jitsi-meet/title*.html /defaults
RUN cp -f /defaults/crontab /etc
RUN chmod 755 /wait-for-it.sh
RUN make all

ENTRYPOINT []

VOLUME ["/config", "/usr/share/jitsi-meet/transcripts"]
