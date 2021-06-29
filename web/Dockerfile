ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base

ADD https://raw.githubusercontent.com/certbot/certbot/v1.9.0/certbot-auto /usr/local/bin/

COPY rootfs/ /

# ENV JITSI_MEET_WEB_VERSION=1.0.4466-1
# ENV JITSI_MEET_WEB_CONFIG_VERSION=1.0.4466-1
ENV JITSI_MEET_WEB_VERSION=1.0.4289-1
ENV JITSI_MEET_WEB_CONFIG_VERSION=1.0.4289-1

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y --allow-unauthenticated cron nginx-extras vim curl make apache2-utils jitsi-meet-web=${JITSI_MEET_WEB_VERSION} && \
	apt-dpkg-wrap apt-get -d install -y --allow-unauthenticated jitsi-meet-web-config=${JITSI_MEET_WEB_CONFIG_VERSION} && \
    dpkg -x /var/cache/apt/archives/jitsi-meet-web-config*.deb /tmp/pkg && \
    mv /tmp/pkg/usr/share/jitsi-meet-web-config/config.js /defaults && \
	mv /usr/share/jitsi-meet/interface_config.js /defaults && \
	apt-cleanup && \
	rm -f /etc/nginx/conf.d/default.conf && \
	rm -rf /tmp/pkg /var/cache/apt

RUN echo "set encoding=utf-8" >> /etc/vim/vimrc

RUN \
	chmod a+x /usr/local/bin/certbot-auto && \
	certbot-auto --no-self-upgrade --noninteractive --install-only

ADD https://deb.nodesource.com/setup_14.x /node_setup.sh
RUN chmod +x /node_setup.sh && /node_setup.sh && rm /node_setup.sh
RUN apt-get install -y nodejs git

WORKDIR /web/jitsi-meet
COPY jitsi-meet/package*.json ./
RUN npm install

COPY jitsi-meet/ /web/jitsi-meet/
RUN cp -f /web/jitsi-meet/interface_config*.js /defaults
RUN cp -f /web/jitsi-meet/config*.js /defaults
RUN cp -f /defaults/crontab /etc
RUN chmod 755 /wait-for-it.sh


ENTRYPOINT []

EXPOSE 80 443

VOLUME ["/config", "/etc/letsencrypt", "/usr/share/jitsi-meet/transcripts"]
