#!/bin/bash -ex

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
		--email $CERT_EMAIL -n --agree-tos \
		--dns-digitalocean --dns-digitalocean-credentials /app/digitalocean.ini \
		--cert-name "$domain" -d \*."$domain" -d "$domain" || return 1
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
	$DOCKER kill -s HUP "$id"
}

if [ -z "$CERT_EMAIL" -o -z "$CERT_DOMAIN" ]; then
	cat >&2 <<EOF
Usage:

Set the following environment variables:

* CERT_EMAIL: The email address to register the certificate for
* CERT_DOMAIN: The domain to request a wild card certificate for

You may optionally set an of the following environment variables:

* CERT_STAGING: set to any value to use the Lets Encrypt staging server instead of production. Useful for testing
EOF
	exit 0
fi

lock=$(mktemp)

for try in {1..5}; do
	registerWildcard roleplay.org.il && break
	echo Waiting 30 seconds before retrying
	sleep 30
done

docker_kill $(get_docker_proxy)

trap "rm -f $lock" 2

while [ -f "$lock" ]; do
	sleep $(( 86400 * $RENEW_CHECK_DAYS ))
	renew
done

exit 0
