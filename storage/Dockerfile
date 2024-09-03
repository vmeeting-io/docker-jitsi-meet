FROM debian:buster-slim

# Set the locale UTF8 to correctly handle non-ASCII chars
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN useradd -ou 0 -g 0 vmeeting
USER vmeeting

ADD https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.1/s6-overlay-amd64-installer /tmp/
RUN chmod +x /tmp/s6-overlay-amd64-installer && /tmp/s6-overlay-amd64-installer /

RUN \
	apt-get update && \
	apt-get install -y openssh-server rsync curl locales &&\
	apt-get clean

RUN locale-gen && \
	sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
	locale-gen

RUN \
	apt-get update && \
	apt-get install -y libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x && \
	apt-get clean

RUN	\
	apt-get install -y gnupg curl && \
	curl -fsSL https://www.mongodb.org/static/pgp/server-4.4.asc | \
   	gpg -o /usr/share/keyrings/mongodb-server-4.4.gpg --dearmor && \
	echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-4.4.gpg ] http://repo.mongodb.org/apt/debian buster/mongodb-org/4.4 main" | \
	tee /etc/apt/sources.list.d/mongodb-org-4.4.list && \
	apt-get update && \
	apt-get install -y mongodb-database-tools

COPY rootfs/ /

RUN chmod 755 /wait-for-it.sh

VOLUME ["/recordings"]

ENTRYPOINT ["/init"]
