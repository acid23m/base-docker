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

db_data_dir=$POSTGRES_DATA

docker run --rm --volumes-from ${COMPOSE_PROJECT_NAME}_db \
    -v $PWD/db/backup:/backup busybox:musl \
    tar -cz -f /backup/backup-$(date +"%Y%m%d").tgz "$db_data_dir"

exit 0
