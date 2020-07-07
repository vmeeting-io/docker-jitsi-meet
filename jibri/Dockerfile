ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base-java

#ARG CHROME_RELEASE=latest
#ARG CHROMEDRIVER_MAJOR_RELEASE=latest
ARG CHROME_RELEASE=78.0.3904.97
ARG CHROMEDRIVER_MAJOR_RELEASE=78

RUN \
	apt-dpkg-wrap apt-get update \
	&& apt-dpkg-wrap apt-get install -y jibri libgl1-mesa-dri \
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
        && curl -4so /tmp/google-chrome-stable_${CHROME_RELEASE}-1_amd64.deb http://dl.google.com/linux/chrome/deb/pool/main/g/google-chrome-stable/google-chrome-stable_${CHROME_RELEASE}-1_amd64.deb \
	&& apt-dpkg-wrap apt-get update \
        && apt-dpkg-wrap apt-get install -y /tmp/google-chrome-stable_${CHROME_RELEASE}-1_amd64.deb \
	&& apt-cleanup \
	|| true

RUN \
	[ "${CHROMEDRIVER_MAJOR_RELEASE}" = "latest" ] \
	&& CHROMEDRIVER_RELEASE="$(curl -4Ls https://chromedriver.storage.googleapis.com/LATEST_RELEASE)" \
	|| CHROMEDRIVER_RELEASE="$(curl -4Ls https://chromedriver.storage.googleapis.com/LATEST_RELEASE_${CHROMEDRIVER_MAJOR_RELEASE})" \
	&& curl -4Ls https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_RELEASE}/chromedriver_linux64.zip \
	| zcat >> /usr/bin/chromedriver \
	&& chmod +x /usr/bin/chromedriver \
	&& chromedriver --version

RUN \
        apt-dpkg-wrap apt-get update \
        && apt-dpkg-wrap apt-get install -y jitsi-upload-integrations jq \
        && apt-cleanup

RUN \
        apt-dpkg-wrap apt-get update \
        && apt-dpkg-wrap apt-get install -y openssh-server rsync \
        && apt-cleanup

RUN \
        apt-dpkg-wrap apt-get update \
        && apt-dpkg-wrap apt-get install -y dbus dbus-x11 pulseaudio pulseaudio-utils rtkit \
        && apt-cleanup
RUN adduser jibri rtkit


RUN mv /usr/bin/google-chrome /usr/bin/google-chrome-bin
RUN mv /usr/bin/ffmpeg /usr/bin/ffmpeg-bin
COPY rootfs/ /

RUN chmod 755 /wait-for-it.sh

RUN \
	chmod 755 /usr/bin/ffmpeg && \
	chmod 755 /usr/bin/google-chrome && \
	chmod 755 /usr/bin/recording_finalize.sh

RUN chown jibri:jibri /home/jibri -R

RUN \
	chmod 600 /home/jibri/.ssh/id_rsa && \
	chmod 600 /home/jibri/.ssh/id_rsa.pub && \
	chmod 644 /etc/ssh/ssh_config

# override the base image s6-overlay entrypoint
ENTRYPOINT []
VOLUME /config

