ARG JITSI_REPO=theun
ARG VMEETING_TAG
FROM ${JITSI_REPO}/base-java

ARG CHROME_RELEASE=126.0.6478.126

ENV JIBRI_VERSION=8.0-169-g1258814-1

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

