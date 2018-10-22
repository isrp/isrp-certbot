#!/bin/bash -ex

EMAIL=${CERT_EMAIL:-web@roleplay.org.il}
if [ -n "$CERT_STAGING" ]; then
	SERVER="--server https://acme-staging-v02.api.letsencrypt.org/directory"
else
	SERVER="--server https://acme-v02.api.letsencrypt.org/directory"
fi
NGINX_PROXY_VOLUME=${NGINX_PROXY_VOLUME:-/certificates}
LETSENCRYPT_VOLUME=${LETSENCRYPT_VOLUME:-/etc/letsencrypt}
RENEW_CHECK_DAYS=${RENEW_CHECK_TIME:-7}

CERTBOT=/usr/local/bin/certbot
DOCKER=/usr/bin/docker

function registerWildcard() {
	local domain="$1"
	$CERTBOT \
		certonly $SERVER \
		--email $EMAIL -n --agree-tos \
		--dns-digitalocean --dns-digitalocean-credentials /app/digitalocean.ini \
		--cert-name "$domain" -d "$domain" -d '*.'"$domain"
	cp -f $LETSENCRYPT_VOLUME/live/$domain/fullchain.pem $NGINX_PROXY_VOLUME/$domain.crt
	cp -f $LETSENCRYPT_VOLUME/live/$domain/privkey.pem $NGINX_PROXY_VOLUME/$domain.key
}

function renew() {
	$CERTBOT renew $SERVER
}

function get_docker_proxy() {
	$DOCKER ps -q --filter label=com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy
}

function docker_kill() {
	local id="$1"
	$DOCKER kill -s INT "$id"
}

lock=$(mktemp)

registerWildcard roleplay.org.il

docker_kill $(get_docker_proxy)

trap "rm -f $lock" 2

while [ -f "$lock" ]; do
	sleep $(( 86400 * $RENEW_CHECK_DAYS ))
	renew
done
