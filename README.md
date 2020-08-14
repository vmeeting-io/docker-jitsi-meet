# Jitsi swarm mode

- Create swarm cluster with 1 manager node. Worker nodes are for replicating jvb and jibri.
- Pre-create pesistent storage folders
    ```shell
    sudo rm -rf ~/.jitsi-meet-cfg
    mkdir -p ~/.jitsi-meet-cfg/{web/letsencrypt,transcripts,jibri,mongo,influxdb,storage,grafana}
    ```
- Deploy
    ```shell
    docker stack deploy --compose-file jitsi_swarm.yml jitsi
    ```
- After deployment, goto `https://{{ HOMEPAGE }}/admin/stats` to have initital setup for grafana monitoring stack.

# Jitsi Meet on Docker

![](resources/jitsi-docker.png)

[Jitsi](https://jitsi.org/) is a set of Open Source projects that allows you to easily build and deploy secure videoconferencing solutions.

[Jitsi Meet](https://jitsi.org/jitsi-meet/) is a fully encrypted, 100% Open Source video conferencing solution that you can use all day, every day — with no account needed.

This repository contains the necessary tools to run a Jitsi Meet stack on [Docker](https://www.docker.com) using [Docker Compose](https://docs.docker.com/compose/).

## Installation

The installation manual is available [here](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker).

## TODO

* Support container replicas (where applicable).
* TURN server.

