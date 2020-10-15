ARG JITSI_REPO=theun

FROM ${JITSI_REPO}/base as builder

RUN \
    apt-dpkg-wrap apt-get update \
    && apt-dpkg-wrap apt-get install -y \
      lua5.2 \
      liblua5.2-dev \
      libsasl2-dev \
      libssl1.0-dev \
      luarocks \
      git \
      gcc \
    && luarocks install cyrussasl 1.1.0-1 \
    && luarocks install lua-cjson 2.1.0-1 \
    && luarocks install luajwtjitsi 1.3-7 \
    && luarocks install net-url 0.9-1 \
    # newer cjson has error: https://github.com/mpx/lua-cjson/issues/56
    && luarocks install lua-cjson 2.1.0-1

FROM ${JITSI_REPO}/base

ADD https://prosody.im/files/prosody-debian-packages.key /tmp/prosody.key

RUN \
    apt-key add /tmp/prosody.key \
    && rm -f /tmp/prosody.key \
    && echo "deb http://packages.prosody.im/debian stretch main" > /etc/apt/sources.list.d/prosody.list \
    && apt-dpkg-wrap apt-get update \
    && apt-dpkg-wrap apt-get install -y \
      prosody \
      libssl1.0.2 \
      sasl2-bin \
      libsasl2-modules-ldap \
      lua-basexx \
      patch \
    && apt-dpkg-wrap apt-get install -t stretch-backports -y \
      lua-ldap \
      lua-sec \
    && apt-cleanup \
    && rm -rf /etc/prosody

ENV JITSI_MEET_PROSODY_VERSION=1.0.4289-1

RUN \
    apt-dpkg-wrap apt-get update \
    && apt-dpkg-wrap apt-get -d install -y jitsi-meet-prosody=${JITSI_MEET_PROSODY_VERSION} \
    && dpkg -x /var/cache/apt/archives/jitsi-meet-prosody*.deb /tmp/pkg \
    && mv /tmp/pkg/usr/share/jitsi-meet/prosody-plugins /prosody-plugins \
    && apt-cleanup \
    && rm -rf /tmp/pkg /var/cache/apt

RUN \
    curl -4so /prosody-plugins/mod_turncredentials.lua \
    https://raw.githubusercontent.com/netaskd/mod_turncredentials/master/mod_turncredentials.lua

COPY rootfs/ /

RUN patch -d /usr/lib/prosody/modules/muc -p0 < /prosody-plugins/muc_owner_allow_kick.patch
RUN patch -d /usr/lib/prosody/modules/ -p2 < /prosody-plugins/mod_websocket_session_event.patch
RUN patch -d /usr/lib/prosody/modules/ -p0 < /prosody-plugins/mod_websocket_smacks.patch

COPY --from=builder /usr/local/lib/lua /usr/local/lib/lua
COPY --from=builder /usr/local/share/lua /usr/local/share/lua

EXPOSE 5222 5347 5280

VOLUME ["/config", "/prosody-plugins-custom"]
