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
container_db=${COMPOSE_PROJECT_NAME}_db

# define database
if [[ "$APP_MODE" = "prod" ]]; then
    DB_NAME=$DB_NAME_PROD
else
    DB_NAME=$DB_NAME_DEV
fi

docker exec -i \
    ${container_db} \
    createdb -U ${DB_USER} -O ${DB_USER} -e ${DB_NAME} || true

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

docker exec -i \
    -w /app \
    ${container_fpm} \
    php ./yii migrate --interactive=0

exit 0
