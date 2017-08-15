FROM resin/rpi-raspbian
MAINTAINER cav94mat

ENV UID=1000 GID=1000
COPY run.sh /bin/run.sh

RUN chmod +x /bin/run.sh && /bin/run.sh --install
VOLUME /data /conf

#EXPOSE 80/tcp 
CMD ["/bin/run.sh"]
