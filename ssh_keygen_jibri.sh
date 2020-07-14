#!/bin/bash

# generate sshkey for jibri
mkdir -p jibri/rootfs/home/jibri/.ssh
yes | ssh-keygen -f jibri/rootfs/home/jibri/.ssh/id_rsa -N "" -C "jibri"

# allow jibri to access storage
mkdir -p storage/rootfs/root/.ssh
cp jibri/rootfs/home/jibri/.ssh/id_rsa.pub storage/rootfs/root/.ssh/authorized_keys
