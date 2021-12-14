ARG JITSI_REPO=theun

FROM ${JITSI_REPO}/base as builder

RUN \
    apt-dpkg-wrap apt-get update \
    && apt-dpkg-wrap apt-get install -y \
      lua5.2 \
      liblua5.2-dev \
      libsasl2-dev \
      libssl-dev \
      luarocks \
      git \
      gcc \
    && luarocks install cyrussasl 1.1.0-1 \
    && luarocks install net-url 0.9-1 \
    && luarocks install luajwtjitsi 2.0-0 \
    # newer cjson has error: https://github.com/mpx/lua-cjson/issues/56
    && luarocks install lua-cjson 2.1.0-1

FROM ${JITSI_REPO}/base

RUN \
    wget -q https://prosody.im/files/prosody-debian-packages.key -O - | gpg --enarmor > /etc/apt/trusted.gpg.d/prosody.asc \
    && echo "deb http://packages.prosody.im/debian buster main" > /etc/apt/sources.list.d/prosody.list \
    && apt-dpkg-wrap apt-get update \
    && apt-dpkg-wrap apt-get install -y \
      prosody \
      libssl1.1 \
      sasl2-bin \
      libsasl2-modules-ldap \
      lua-basexx \
      patch \
      lua-ldap \
      lua-sec \
      vim inotify-tools \
    && apt-cleanup \
    && rm -rf /etc/prosody

RUN echo "set encoding=utf-8" >> /etc/vim/vimrc

ENV JITSI_MEET_PROSODY_VERSION=1.0.4985-1

RUN \
    apt-dpkg-wrap apt-get update \
    && apt-dpkg-wrap apt-get -d install -y jitsi-meet-prosody=${JITSI_MEET_PROSODY_VERSION} \
    && dpkg -x /var/cache/apt/archives/jitsi-meet-prosody*.deb /tmp/pkg \
    && mv /tmp/pkg/usr/share/jitsi-meet/prosody-plugins /prosody-plugins \
    && apt-cleanup \
    && rm -rf /tmp/pkg /var/cache/apt

COPY rootfs/ /

RUN patch -d /usr/lib/prosody/modules/muc -p0 < /prosody-plugins/muc_owner_allow_kick.patch

COPY --from=builder /usr/local/lib/lua /usr/local/lib/lua
COPY --from=builder /usr/local/share/lua /usr/local/share/lua

EXPOSE 5222 5347 5280

VOLUME ["/config", "/prosody-plugins-custom"]
