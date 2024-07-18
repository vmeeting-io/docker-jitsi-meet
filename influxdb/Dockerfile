FROM influxdb:1.8

COPY rootfs/ /
RUN chmod +x /init-permission.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]