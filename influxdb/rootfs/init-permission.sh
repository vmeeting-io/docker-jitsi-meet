#!/bin/bash

# for secure connection
chown influxdb:influxdb /etc/ssl/influxdb.*

# for password permission
chmod 640 /var/lib/influxdb/meta/meta.db
chown influxdb:influxdb /var/lib/influxdb/meta/meta.db

# for environment file access permission
chmod 640 /etc/influxdb/influxdb.conf
chown influxdb:influxdb /etc/influxdb/influxdb.conf

