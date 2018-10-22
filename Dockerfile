FROM certbot/dns-digitalocean

ENV LC_ALL=en_US.UTF-8 LC_CTYPE=en_US.UTF-8
RUN apk --no-cache add bash docker
WORKDIR /app
RUN mkdir -p /certificates
VOLUME /certificates
ADD isrp-start.sh /app/isrp-start
ENTRYPOINT [ "/app/isrp-start" ]
