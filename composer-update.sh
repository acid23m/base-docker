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
        composer update --prefer-dist --no-dev --optimize-autoloader
else
    docker exec -i \
        -w /app \
        ${container_fpm} \
        composer update --prefer-dist --optimize-autoloader
fi

exit 0
