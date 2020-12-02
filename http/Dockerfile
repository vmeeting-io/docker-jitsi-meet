ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base

ADD https://raw.githubusercontent.com/certbot/certbot/v1.9.0/certbot-auto /usr/local/bin/

COPY rootfs/ /

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y cron nginx-extras vim curl && \
	apt-cleanup && \
	rm -f /etc/nginx/conf.d/default.conf && \
	rm -rf /tmp/pkg /var/cache/apt

RUN \
	chmod a+x /usr/local/bin/certbot-auto && \
	certbot-auto --noninteractive --install-only

EXPOSE 80 443 8080

VOLUME ["/config", "/etc/letsencrypt"]
