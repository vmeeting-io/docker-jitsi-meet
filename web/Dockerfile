ARG JITSI_REPO=theun
ARG VMEETING_TAG
FROM ${JITSI_REPO}/base

ADD https://raw.githubusercontent.com/acmesh-official/acme.sh/2.8.8/acme.sh /opt

COPY rootfs/ /

# ENV JITSI_MEET_WEB_VERSION=1.0.4466-1
# ENV JITSI_MEET_WEB_CONFIG_VERSION=1.0.4466-1
ENV JITSI_MEET_WEB_VERSION=1.0.4289-1
ENV JITSI_MEET_WEB_CONFIG_VERSION=1.0.4289-1

RUN \
	# 0) Debian 미러를 확실히 bullseye로 고정(혼용 방지) \
	printf 'deb http://deb.debian.org/debian bullseye main\n' \
	      'deb http://deb.debian.org/debian bullseye-updates main\n' \
	      'deb http://security.debian.org/debian-security bullseye-security main\n' \
	      > /etc/apt/sources.list && \
	\
	apt-dpkg-wrap apt-get update && \
	apt-get install -y --no-install-recommends ca-certificates curl gnupg apt-transport-https && \
	mkdir -p /usr/share/keyrings && \
	\
	# 1) Jitsi repo: apt-key 제거 -> keyring + signed-by \
	curl -fsSL https://download.jitsi.org/jitsi-key.gpg.key | gpg --dearmor -o /usr/share/keyrings/jitsi.gpg && \
	echo "deb [signed-by=/usr/share/keyrings/jitsi.gpg] https://download.jitsi.org stable/" \
	  > /etc/apt/sources.list.d/jitsi-stable.list && \
	\
	# 2) NGINX repo: bullseye용 signed-by 등록(기존 잔여 엔트리 제거) \
	sed -i '/nginx\.org\/packages\/debian/d' /etc/apt/sources.list || true && \
	rm -f /etc/apt/sources.list.d/nginx*.list /etc/apt/trusted.gpg.d/nginx*.gpg /etc/apt/trusted.gpg.d/nginx*.asc || true && \
	curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
	  | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null && \
	echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] https://nginx.org/packages/debian bullseye nginx' \
	  > /etc/apt/sources.list.d/nginx.list && \
	\
	# 3) 설치( --allow-unauthenticated 제거 ) \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y cron nginx vim curl make apache2-utils jitsi-meet-web=${JITSI_MEET_WEB_VERSION} socat && \
	apt-dpkg-wrap apt-get -d install -y jitsi-meet-web-config=${JITSI_MEET_WEB_CONFIG_VERSION} && \
	dpkg -x /var/cache/apt/archives/jitsi-meet-web-config*.deb /tmp/pkg && \
	mv /tmp/pkg/usr/share/jitsi-meet-web-config/config.js /defaults && \
	mv /usr/share/jitsi-meet/interface_config.js /defaults && \
	apt-cleanup && \
	rm -f /etc/nginx/conf.d/default.conf && \
	rm -rf /tmp/pkg /var/cache/apt

RUN echo "set encoding=utf-8" >> /etc/vim/vimrc

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
	apt-get install -y nodejs git

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

EXPOSE 80 443

VOLUME ["/config", "/usr/share/jitsi-meet/transcripts"]
