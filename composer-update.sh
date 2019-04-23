#!/usr/bin/env bash

set -ae
. ./.env
set +a

container_fpm=${COMPOSE_PROJECT_NAME}_fpm

docker exec -i \
    -w /app \
    ${container_fpm} \
    composer self-update

if [[ "$APP_MODE" = "prod" ]]; then
    docker exec -i \
        -w /app \
        ${container_fpm} \
        composer update --prefer-dist --no-dev --no-suggest --optimize-autoloader
    docker exec -i \
        -w /app \
        ${container_fpm} \
        composer dump-autoload --optimize --no-dev --classmap-authoritative
else
    docker exec -i \
        -w /app \
        ${container_fpm} \
        composer update --prefer-dist --optimize-autoloader -vvv
    docker exec -i \
        -w /app \
        ${container_fpm} \
        composer dump-autoload --optimize -vvv
fi

docker exec -i \
    -w /app \
    ${container_fpm} \
    composer clear-cache

exit 0
