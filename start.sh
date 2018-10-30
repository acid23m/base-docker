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
if [[ ! -f "$PWD/conf/certs/cert.key" ]] || [[ ! -f "$PWD/conf/certs/cert.crt" ]]; then
    openssl req -x509 -nodes -newkey rsa:4096 -days 36500 \
        -keyout "$PWD/conf/certs/cert.key" \
        -out "$PWD/conf/certs/cert.crt" \
        -subj "/C=RU/ST=RU/L=Internet/O=$(hostname -s)/CN=${SITE_DOMAIN}"
fi

# define database
if [[ "$APP_MODE" = "prod" ]]; then
    export DB_NAME=$DB_NAME_PROD
else
    export DB_NAME=$DB_NAME_DEV
fi

# run containers
docker-compose -p ${COMPOSE_PROJECT_NAME} up -d --build

# add user
if [[ $(id -u) != 0 ]]; then
    docker exec -i \
        ${container_fpm} \
        useradd -M -u 1000 -G www-data $(id -un)
fi

# update os and install additional soft
docker exec -i \
    ${container_fpm} \
    bash -c \
        "apt update && apt dist-upgrade -y && apt full-upgrade -y"

if [ -n "${ADDITIONAL_SOFT_LIST}" ]; then
    docker exec -i \
        ${container_fpm} \
        bash -c \
            "apt install -ym --no-install-recommends --no-install-suggests ${ADDITIONAL_SOFT_LIST}"
fi

docker exec -i \
    ${container_fpm} \
    bash -c \
        "apt autoclean -y && apt autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*"

exit 0
