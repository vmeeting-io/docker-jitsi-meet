ARG JITSI_REPO=theun
FROM ${JITSI_REPO}/base

ARG ROOT_PASSWD=vmeeting
RUN echo "root:${ROOT_PASSWD}" | chpasswd

# xrdp
RUN \
    echo "deb http://ftp.debian.org/debian stretch-backports main" >> /etc/apt/sources.list && \
    apt-dpkg-wrap apt-get update && \
    apt-dpkg-wrap apt-get install -y wget openbox xvfb xterm && \
    apt-dpkg-wrap apt-get -t stretch-backports install -y xrdp xorgxrdp && \
    apt-cleanup

ENV HOME=/root \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=C.UTF-8 \
    DISPLAY=:0

RUN mkdir -p /var/run/xrdp/sockdir

RUN mkdir -p /etc/services.d && cd /etc/services.d && mkdir -p openbox xvfb xrdp xrdp-sesman && ls -lha /etc/services.d/
RUN echo "#!/usr/bin/with-contenv bash\nexec openbox" > /etc/services.d/openbox/run && \
    echo "#!/usr/bin/with-contenv bash\nexec /usr/sbin/xrdp -nodaemon" > /etc/services.d/xrdp/run && \
    echo "#!/usr/bin/with-contenv bash\nexec /usr/sbin/xrdp-sesman --nodaemon" > /etc/services.d/xrdp-sesman/run && \
    echo "#!/usr/bin/with-contenv bash\nexec Xvfb :0 -screen 0 1920x1080x24 -listen tcp -ac" > /etc/services.d/xvfb/run

# IDEA
RUN wget -q https://download-cf.jetbrains.com/idea/ideaIC-2020.2.3.tar.gz && \
    mkdir -p /opt/idea && \
    tar -xzf ideaIC-2020.2.3.tar.gz -C /opt/idea --strip-components 1
