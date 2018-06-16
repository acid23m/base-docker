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

exit 0
