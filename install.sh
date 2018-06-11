#!/usr/bin/env bash

# check .env file
if [[ -f "$PWD/.env" ]]; then
    echo "Installing.."
else
    echo ".env file not found.\nCopy it from .env.example ang configure."
    exit 1
fi

set -ae
. ./.env
set +a

container_fpm=${COMPOSE_PROJECT_NAME}_fpm

# add user
if [[ $(id -u) != 0 ]]; then
    docker exec -i \
        ${container_fpm} \
        useradd -M -u 1000 -G www-data $(id -un)
fi

# create configs
cp -a ./common/config/app.example.ini ./common/config/app.ini
cp -a ./common/config/maintance.example.ini ./common/config/maintance.ini
cp -a ./common/config/script.example.ini ./common/config/script.ini

# install dependencies
if [[ "$APP_MODE" = "prod" ]]; then
    docker exec -i \
        -w /app \
        ${container_fpm} \
        composer install --prefer-dist --no-dev --no-suggest --optimize-autoloader
else
    docker exec -i \
        -w /app \
        ${container_fpm} \
        composer install --prefer-dist --no-suggest --optimize-autoloader
fi

# init framework
if [[ "$APP_MODE" = "prod" ]]; then
    docker exec -i \
        -w /app \
        ${container_fpm} \
        php ./init --env=Production --overwrite=All
else
    docker exec -i \
        -w /app \
        ${container_fpm} \
        php ./init --env=Development --overwrite=All
fi

# create db
docker exec -i \
    -w /app \
    ${container_fpm} \
    php ./yii migrate --interactive=0

# request for auto generating db
curl \
    --connect-timeout 60 \
    --http1.1 \
    --insecure \
    --keepalive-time 60 \
    --location \
    --silent \
    --show-error \
    --head \
    --url "http://${SITE_DOMAIN}/admin"

# create RBAC config
docker exec -i \
    -w /app \
    ${container_fpm} \
    php ./yii access/user/rbac

# create user
docker exec -i \
    -w /app \
    ${container_fpm} \
    php ./yii access/user/create $MAIN_USER_NAME $MAIN_USER_EMAIL $MAIN_USER_PASSWORD root --force=yes

# app dir permissions
if [[ $(id -u) -eq 0 ]]; then
    sudo $PWD/bin/access -u www-data -p $PWD/app/
else
    sudo $PWD/bin/access -u $(id -un) -p $PWD/app/
fi

exit 0
