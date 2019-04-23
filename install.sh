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

# app dir permissions
permissions() {
    if [[ $(id -u) -eq 0 ]]; then
        sudo "$PWD/bin/appperm" -c "$PWD/conf/appperm/appperm.yml" -u www-data "$PWD/app/"
        sudo chown -R www-data:www-data .
    else
        sudo "$PWD/bin/appperm" -c "$PWD/conf/appperm/appperm.yml" -u $(id -un) "$PWD/app/"
        sudo chown -R $(id -un):www-data .
    fi
}


# install dependencies
if [[ "$APP_MODE" = "prod" ]]; then
    docker exec -i \
        -w /app \
        ${container_fpm} \
        composer install --prefer-dist --no-dev --no-suggest --optimize-autoloader
    docker exec -i \
        -w /app \
        ${container_fpm} \
        composer dump-autoload --optimize --no-dev --classmap-authoritative
else
    docker exec -i \
        -w /app \
        ${container_fpm} \
        composer install --prefer-dist --no-suggest --optimize-autoloader
    docker exec -i \
        -w /app \
        ${container_fpm} \
        composer dump-autoload --optimize
fi

docker exec -i \
    -w /app \
    ${container_fpm} \
    composer clear-cache

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

permissions

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
    --url "http://${SITE_DOMAIN}/admin" || true

# create additional directories
docker exec -i \
    -w /app \
    ${container_fpm} \
    bash -c "mkdir -p ./userdata/files/uploads ./userdata/images/uploads"

permissions

exit 0
