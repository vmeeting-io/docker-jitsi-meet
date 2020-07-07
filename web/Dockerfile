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

ARG REACT_APP_AUTH_PAGE_BASE
ARG REACT_APP_AUTH_API_BASE
ARG REACT_APP_JWT_TOKEN
ENV REACT_APP_AUTH_PAGE_BASE=${REACT_APP_AUTH_PAGE_BASE}
ENV REACT_APP_AUTH_API_BASE=${REACT_APP_AUTH_API_BASE}
ENV REACT_APP_JWT_TOKEN=${REACT_APP_JWT_TOKEN}

COPY jitsi-meet/ /web/jitsi-meet/
RUN cp -f /web/jitsi-meet/interface_config.js /defaults
RUN echo REACT_APP_AUTH_API_BASE=${REACT_APP_AUTH_API_BASE} > .env \
  && echo REACT_APP_AUTH_PAGE_BASE=${REACT_APP_AUTH_PAGE_BASE} >> .env \
  && echo REACT_APP_JWT_TOKEN=${REACT_APP_JWT_TOKEN} >> .env

RUN make

EXPOSE 80 443

VOLUME ["/config", "/etc/letsencrypt", "/usr/share/jitsi-meet/transcripts"]
