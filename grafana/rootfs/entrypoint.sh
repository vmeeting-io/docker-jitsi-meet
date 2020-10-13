#!/bin/bash
#
# initial configuration for grafana dashboard before running grafana
#
set -x

function set_vm_home_dashboard {
    echo "Wait for grafana to be ready..."
    while ! nc -z localhost 3000; do
        sleep 1
    done

    # vmeeting dashboard id is 1 because it is the only one provisioned
    curl \
        --request PUT \
        --header 'Content-Type: application/json' \
        --data '{ "homeDashboardId": 1 }' \
        http://admin:admin@localhost:3000/api/user/preferences

}


# set vmeeting dashboard title to domain name
DOMAIN_NAME=$(echo $PUBLIC_URL | cut -d '/' -f 3)
sed -i "s/#DOMAIN_NAME/$DOMAIN_NAME/g" /etc/grafana/provisioning/jitsi/jitsi.json

# need to run at background for grafana to start to run
set_vm_home_dashboard &

# start grafana entrypoint
/run.sh "$@"
