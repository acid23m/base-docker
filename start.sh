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

container_fpm=${COMPOSE_PROJECT_NAME}_fpm

# create certificates
if [[ ! -f "$PWD/conf/certs/dhparam.pem" ]]; then
    openssl dhparam -out ./conf/certs/dhparam.pem -dsaparam 4096
fi
if [[ ! -f "$PWD/conf/certs/self-signed.key" ]] || [[ ! -f "$PWD/conf/certs/self-signed.crt" ]]; then
    openssl req -x509 -nodes -newkey rsa:4096 -days 36500 -keyout \
        ./conf/certs/self-signed.key -out \
        ./conf/certs/self-signed.crt \
        -subj /C=AA/ST=AA/L=Internet/O=MailInABox/CN=APP
fi

if [[ "$APP_MODE" = "prod" ]]; then
    export DB_NAME=$DB_NAME_PROD
    export DB_USER=$DB_USER_PROD
    export DB_PASSWORD=$DB_PASSWORD_PROD
else
    export DB_NAME=$DB_NAME_DEV
    export DB_USER=$DB_USER_DEV
    export DB_PASSWORD=$DB_PASSWORD_DEV
fi

# run containers
docker-compose -p $COMPOSE_PROJECT_NAME up -d --build

# add user
if [[ $(id -u) != 0 ]]; then
    docker exec -i \
        ${container_fpm} \
        useradd -M -u 1000 -G www-data $(id -un)
fi

exit 0
