# syntax=docker/dockerfile:1.2

# ARG JITSI_REPO=theun

# FROM ${JITSI_REPO}/base as builder
# RUN	\
# 	mkdir -p /usr/share/man/man1 && \
# 	wget -q https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public -O /etc/apt/trusted.gpg.d/openjdk.asc && \
# 	echo "deb https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ buster main" > /etc/apt/sources.list.d/openjdk.list && \
# 	apt-dpkg-wrap apt-get update && \
# 	apt-dpkg-wrap apt-get install -y openjdk-11-jdk-headless && \
# 	apt-cleanup

# RUN \
#     cd /opt/ && \
#     wget -q http://apache.mirrors.pair.com/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz && \
#     tar -xvzf apache-maven-3.5.4-bin.tar.gz && \
#     mv apache-maven-3.5.4 maven
# ENV M2_HOME=/opt/maven
# ENV PATH=${M2_HOME}/bin:${PATH}

# COPY jibri /jibri

# WORKDIR /jibri
# RUN --mount=type=cache,target=/root/.m2 mvn clean package -P buildFatJar


# TODO: use jre 11 instead of jre 8 same with base-java when this bug is fixed
# https://github.com/jitsi/jibri/issues/441
ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base

RUN	\
	mkdir -p /usr/share/man/man1 && \
	wget -q https://adoptopenjdk.jfrog.io/adoptopenjdk/api/gpg/key/public -O /etc/apt/trusted.gpg.d/openjdk.asc && \
	echo "deb https://adoptopenjdk.jfrog.io/adoptopenjdk/deb/ buster main" > /etc/apt/sources.list.d/openjdk.list && \
	apt-dpkg-wrap apt-get update && \
	apt-dpkg-wrap apt-get install -y adoptopenjdk-8-hotspot-jre && \
	apt-cleanup

#ARG CHROME_RELEASE=latest
#ARG CHROMEDRIVER_MAJOR_RELEASE=latest
ARG CHROME_RELEASE=96.0.4664.45
ARG CHROMEDRIVER_MAJOR_RELEASE=96

ENV JIBRI_VERSION=8.0-93-g51fe7a2-1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
	apt-dpkg-wrap apt-get update \
	&& apt-dpkg-wrap apt-get install -y jibri=${JIBRI_VERSION} libgl1-mesa-dri libnss3-dev \
	&& apt-cleanup

RUN \
	[ "${CHROME_RELEASE}" = "latest" ] \
	&& curl -4s https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
	&& echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
	&& apt-dpkg-wrap apt-get update \
	&& apt-dpkg-wrap apt-get install -y google-chrome-stable \
	&& apt-cleanup \
	|| true

RUN \
	[ "${CHROME_RELEASE}" != "latest" ] \
	&& curl -4so "/tmp/google-chrome-stable_${CHROME_RELEASE}-1_amd64.deb" "http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_RELEASE}-1_amd64.deb" \
	&& apt-dpkg-wrap apt-get update \
	&& apt-dpkg-wrap apt-get install -y "/tmp/google-chrome-stable_${CHROME_RELEASE}-1_amd64.deb" \
	&& apt-cleanup \
	|| true

RUN \
	[ "${CHROMEDRIVER_MAJOR_RELEASE}" = "latest" ] \
	&& CHROMEDRIVER_RELEASE="$(curl -4Ls https://chromedriver.storage.googleapis.com/LATEST_RELEASE)" \
	|| CHROMEDRIVER_RELEASE="$(curl -4Ls https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROMEDRIVER_MAJOR_RELEASE})" \
	&& curl -4Ls "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_RELEASE}/chromedriver_linux64.zip" \
	| zcat >> /usr/bin/chromedriver \
	&& chmod +x /usr/bin/chromedriver \
	&& chromedriver --version

RUN \
	apt-dpkg-wrap apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4EB27DB2A3B88B8B \
	&& apt-dpkg-wrap apt-get update \
	&& apt-dpkg-wrap apt-get install -y jitsi-upload-integrations jq fonts-noto fonts-noto-cjk openssh-server rsync dos2unix dbus-x11 pulseaudio rtkit vim \
	&& apt-cleanup

RUN adduser jibri rtkit


RUN echo "set encoding=utf-8" >> /etc/vim/vimrc

RUN mv /usr/bin/google-chrome /usr/bin/google-chrome-bin
RUN mv /usr/bin/ffmpeg /usr/bin/ffmpeg-bin
COPY rootfs/ /

RUN chmod 755 /wait-for-it.sh

RUN \
	chmod 755 /usr/bin/ffmpeg && \
	chmod 755 /usr/bin/google-chrome && \
	chmod 755 /usr/bin/recording_finalize.sh

RUN chown jibri:jibri /home/jibri -R

RUN chmod 644 /etc/ssh/ssh_config

# COPY --from=builder /jibri/target/jibri-8.0-SNAPSHOT-jar-with-dependencies.jar /opt/jitsi/jibri/jibri.jar

# override the base image s6-overlay entrypoint
ENTRYPOINT []
VOLUME /config

