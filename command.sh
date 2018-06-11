#!/usr/bin/env bash

set -ae
. ./.env
set +a

container_fpm=${COMPOSE_PROJECT_NAME}_fpm

docker exec -it \
    -w /app \
    ${container_fpm} \
    bash
