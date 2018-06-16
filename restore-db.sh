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

# define backup
read -p "Enter backup filename from /db/backup without path: " backup_filename

if [[ ! -f "$PWD/db/backup/${backup_filename}" ]]; then
    echo "File not found."
    exit 2
fi

db_data_dir=/var/lib/postgresql/data

docker run --rm -v ${COMPOSE_PROJECT_NAME}_db-data:"${db_data_dir}":rw \
    -v $PWD/db/backup:/backup busybox:musl \
    /bin/sh -c "rm -rf ${db_data_dir}/* && tar -xz -C / -f /backup/${backup_filename}"

exit 0
