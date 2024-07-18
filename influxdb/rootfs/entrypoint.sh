#!/bin/bash
set -e

# create self-signed certificates
CERT_KEY="/etc/ssl/influxdb.key"
CERT_CRT="/etc/ssl/influxdb.crt"
HOST="$( (hostname -s; echo localhost) | head -n 1)"
DOMAIN="$( (hostname -d; echo localdomain) | head -n 1)"
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj \
    "/O=$DOMAIN/OU=$HOST/CN=influxdb/emailAddress=webmaster@$HOST.$DOMAIN" \
    -keyout $CERT_KEY \
    -out $CERT_CRT \
    -reqexts SAN \
    -extensions SAN \
    -config <(cat /etc/ssl/openssl.cnf \
        <(printf "[SAN]\nsubjectAltName=DNS:localhost,DNS:influxdb"))


if [ "${1:0:1}" = '-' ]; then
    set -- influxd "$@"
fi

if [ "$1" = 'influxd' ]; then
	/init-influxdb.sh "${@:2}"
fi

/init-permission.sh

exec "$@"