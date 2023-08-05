FROM influxdb:1.8

RUN useradd -ou 0 -g 0 vmeeting
USER vmeeting

ENTRYPOINT ["/entrypoint.sh"]
CMD ["influxd"]