#!/bin/bash
#
# initial configuration for grafana dashboard before running grafana
#
set -x

DOMAIN_NAME=$(echo $PUBLIC_URL | cut -d '/' -f 3)
sed -i "s/#DOMAIN_NAME/$DOMAIN_NAME/g" /etc/grafana/provisioning/jitsi/jitsi.json

# start grafana entrypoint
/run.sh "$@"
