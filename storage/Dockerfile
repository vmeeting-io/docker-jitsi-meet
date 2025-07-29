ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base

# Set the locale UTF8 to correctly handle non-ASCII chars
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y openssh-server rsync curl locales && \
	apt-cleanup

RUN locale-gen && \
	sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
	locale-gen

RUN \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y libgstreamer1.0-0 gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly gstreamer1.0-libav gstreamer1.0-tools gstreamer1.0-x && \
	apt-cleanup

RUN	\
	apt-get install -y gnupg curl && \
	curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | \
   	gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor && \
	echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/6.0 main" | \
	tee /etc/apt/sources.list.d/mongodb-org-6.0.list && \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y mongodb-database-tools && \
	apt-cleanup

RUN \
    mkdir -p /run/sshd && \
    mkdir -p /var/run/sshd

COPY rootfs/ /

RUN chmod 755 /wait-for-it.sh

VOLUME ["/recordings"]

ENTRYPOINT ["/init"]
