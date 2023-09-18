# syntax=docker/dockerfile:1.2

# ARG JITSI_REPO=theun
# ARG VMEETING_TAG
# FROM ${JITSI_REPO}/base:${VMEETING_TAG} as builder
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
ARG VMEETING_TAG
FROM ${JITSI_REPO}/base:${VMEETING_TAG}

RUN	\
	mkdir -p /usr/share/man/man1 && \
    apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y openjdk-11-jre-headless && \
    apt-cleanup

#ARG CHROME_RELEASE=latest
#ARG CHROMEDRIVER_MAJOR_RELEASE=latest
ARG CHROME_RELEASE=114.0.5735.90
ARG CHROMEDRIVER_MAJOR_RELEASE=114

ENV JIBRI_VERSION=8.0-105-gddca7a2-1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN \
	apt-dpkg-wrap apt-get update \
	&& apt-dpkg-wrap apt-get install -y jibri=${JIBRI_VERSION} libgl1-mesa-dri libnss3-dev unzip \
	&& apt-cleanup

RUN \
	apt-dpkg-wrap apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 4EB27DB2A3B88B8B \
	&& apt-dpkg-wrap apt-get update \
	&& apt-dpkg-wrap apt-get install -y jitsi-upload-integrations jq fonts-noto fonts-noto-cjk openssh-server rsync dos2unix dbus-x11 pulseaudio rtkit vim \
	&& apt-cleanup

COPY install-chrome.sh /install-chrome.sh
RUN /install-chrome.sh
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

