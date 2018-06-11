#!/usr/bin/env bash

# check .env file
if [[ -f "$PWD/.env" ]]; then
    echo "Running.."
else
    echo -e ".env file not found.\nCopy it from .env.example ang configure."
    exit 1
fi

set -ae
. ./.env
set +a

# clear logs
sudo rm -f ./logs/fpm/*.log ./logs/nginx/*.log ./logs/php/*.log ./logs/postgresql/*.log

# create certificates
sudo openssl dhparam -out ./conf/certs/dhparam.pem 2048
sudo openssl req -x509 -nodes -newkey rsa:2048 -days 36500 -keyout ./conf/certs/self-signed.key -out ./conf/certs/self-signed.crt -subj /C=AA/ST=AA/L=Internet/O=MailInABox/CN=APP

# run containers
if [[ "$USE_LETSENCRYPT" = "yes" ]]; then
    docker-compose -f docker-compose.le.yml up -d --build
else
    docker-compose up -d --build
fi

exit 0
