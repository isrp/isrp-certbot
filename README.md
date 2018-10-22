# ISRP Nginx Proxy Certificate Generator

This is a companion docker to `jwilder/nginx-proxy` for docker virtual hosting. It uses Lets Encrypt
certbot to generate one wildcard certificate for use in the Nginx proxy configuration.

It aims to achieve a similar (but more more limited) configuration as `jrcs/letsencrypt-nginx-proxy-companion`,
except its sole purpose is to create a wildcard certificate that the mentioned container does not (yet?) support.

## Setup

### Nginx Proxy configuration

In your docker-compose file containing the Nginx proxy:

1. Make sure the `nginx-proxy` service is labeled with the label
`com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy`, similar to the setup for 
`jrcs/letsencrypt-nginx-proxy-companion`.
2. Make sure is has a volume mounted to `/etc/nginx/certs` so it can receive the certificates generated.
This volume can be local to the composition, though its probably better to have it shared to the host.
3. Make sure the restart policy is set to `always`.
4. Expose port 443.

#### Sample configuration:

````
  nginx-proxy:
    image: jwilder/nginx-proxy
    ports:
      - "80:80"
      - "443:443"
    environment:
      ENABLE_IPV6: "true"
      DEFAULT_HOST: roleplay.org.il
    labels:
      - com.github.jrcs.letsencrypt_nginx_proxy_companion.nginx_proxy
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - /etc/ssl/proxy-certs:/etc/nginx/certs:ro
    restart: always
```

### ISRP Certbot configuration

First you need to get a Digital Ocean API key so the certbot can generate verification code in your
Digital Ocean hosted domain: 

1. Log in to the Digital Ocean console and click "API".
2. Create a new personal access token with write permissions.
3. Copy the token code presented.
4. Create a file on the server, somewhere that is relatively secure, like the `/etc/ssl` directory, call it `digitalocean.ini` and make sure it is owned by `root` and has permissions only for `root` (e.g. mode `0600`).
5. In the INI file add a line to configure the API token, using the format: `dns_digitalocean_token = <copied token>`

In your docker-compose file, add a service for `isrp/isrp-certbot`, and configure it:

1. Specify the environment variable `CERT_EMAIL` to the email you want to receive expiration notifications on.
2. Specify the environment variable `CERT_DOMAIN` to the domain you want `isrp-certbot` to create a wildcard cartificate for.
3. Setup a volume to mount the ceritificate volume of the Nginx proxy to the `/certificate` directory in the container.
4. Setup a volume to access the Docker socket, like with Nginx proxy, to `/var/run/docker.sock` in the container.
5. Setup a volume to access the `digitalocean.ini` through the container path `/app/digitalocean.ini`.
6. Setup the restart policy to be `on-failure`.

#### Sample configuration:

```
  isrp-certbot:
    image: isrp/isrp-certbot
    environment:
      CERT_EMAIL: web@roelplay.org.il
      CERT_DOMAIN: roleplay.org.il
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /etc/ssl/digitalocean.ini:/app/digitalocean.ini
      - /etc/ssl/proxy-certs:/certiicates
    restart: on-failure
```

## Development and local testing

For development:

1. Create a `digitalocean.ini` like the setup instructions, except in the local development root folder.
2. Use the `test-compose.yaml` file to launch a testing configuration as so:

```
docker-compose -f test-compose.yaml up
```

To reset the configuration:

```
docker-compose -f test-compose.yaml down
docker volume rm isrp-certbot_test-certs
```

