ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base

ADD https://dl.eff.org/certbot-auto /usr/local/bin/

COPY rootfs/ /

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y cron nginx-extras vim curl make jitsi-meet-web && \
	apt-dpkg-wrap apt-get -d install -y jitsi-meet-web-config && \
    dpkg -x /var/cache/apt/archives/jitsi-meet-web-config*.deb /tmp/pkg && \
    mv /tmp/pkg/usr/share/jitsi-meet-web-config/config.js /defaults && \
	mv /usr/share/jitsi-meet/interface_config.js /defaults && \
	apt-cleanup && \
	rm -f /etc/nginx/conf.d/default.conf && \
	rm -rf /tmp/pkg /var/cache/apt

RUN \
	chmod a+x /usr/local/bin/certbot-auto && \
	certbot-auto --noninteractive --install-only

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs git

WORKDIR /web/jitsi-meet
COPY jitsi-meet/package*.json ./
RUN npm install

COPY jitsi-meet/ /web/jitsi-meet/
RUN cp -f /web/jitsi-meet/interface_config.js /defaults
RUN cp -f /web/jitsi-meet/config.js /defaults

RUN chmod 755 /wait-for-it.sh

ARG VMEETING_FRONT_BASE
ARG VMEETING_API_BASE
ARG JWT_APP_ID
ENV VMEETING_FRONT_BASE=${VMEETING_FRONT_BASE}
ENV VMEETING_API_BASE=${VMEETING_API_BASE}
ENV JWT_APP_ID=${JWT_APP_ID}

RUN echo VMEETING_FRONT_BASE=${VMEETING_FRONT_BASE} > .env \
  && echo VMEETING_API_BASE=${VMEETING_API_BASE} >> .env \
  && echo JWT_APP_ID=${JWT_APP_ID} >> .env

ENTRYPOINT []

EXPOSE 80 443

VOLUME ["/config", "/etc/letsencrypt", "/usr/share/jitsi-meet/transcripts"]
