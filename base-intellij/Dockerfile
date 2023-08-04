ARG JITSI_REPO=theun
ARG VMEETING_TAG
FROM ${JITSI_REPO}/base:${VMEETING_TAG}

ARG DEV_ROOT_PASSWD=vmeeting
RUN echo "root:${DEV_ROOT_PASSWD}" | chpasswd

# xrdp
RUN \
    # echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list && \
    apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y wget openbox xterm && \
    apt-dpkg-wrap apt-get install -y xrdp xorgxrdp && \
    apt-cleanup

# IDEA
RUN wget -q https://download-cf.jetbrains.com/idea/ideaIC-2020.2.3.tar.gz && \
    mkdir -p /opt/idea && \
    tar -xzf ideaIC-2020.2.3.tar.gz -C /opt/idea --strip-components 1

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    DISPLAY=:0

RUN mkdir -p /var/run/xrdp/sockdir

RUN mkdir -p /etc/services.d && cd /etc/services.d && mkdir -p openbox xrdp xrdp-sesman
RUN echo "#!/usr/bin/with-contenv bash\nexec openbox" > /etc/services.d/openbox/run && \
    echo "#!/usr/bin/with-contenv bash\nexec /usr/sbin/xrdp -nodaemon" > /etc/services.d/xrdp/run && \
    echo "#!/usr/bin/with-contenv bash\nexec /usr/sbin/xrdp-sesman --nodaemon" > /etc/services.d/xrdp-sesman/run

# make RDP faster. we dev internally so crypt_level to none is ok
# https://superuser.com/questions/1539900/slow-ubuntu-remote-desktop-using-xrdp
RUN sed -i 's/crypt_level=.*/crypt_level=none/g' /etc/xrdp/xrdp.ini
