#!/usr/bin/env bash

# When the files to be monitored are changed, prosody will be restart.

if [[ $# -eq 0 ]]; then
    echo "You need to pass the folders to be monitored.";
    exit 0;
fi

for f in "$@"; do
    if [ ! -f "$f" ]; then
    if [ ! -d "$f" ]; then
        echo "Invalid folder passed: $f";
        exit 0;
    fi
    fi
done

while [ 1 ]; do
    inotifywait -e modify,create -r $*;
    s6-svc -t /var/run/s6/services/prosody;
done
