#!/bin/bash -x

DRYRUN=--dry-run
EMAIL=web@roleplay.org.il

CERTBOT=/usr/local/bin/certbot
$CERTBOT --help certonly
$CERTBOT certonly --manual -n \
	$DRYRUN \
	--preferred-challenges=dns \
	--dns-digitalocean \
	--email $EMAIL \
	--server https://acme-v02.api.letsencrypt.org/directory \
	--agree-tos \
	--cert-name roleplay.org.il -d *.roleplay.org.il
