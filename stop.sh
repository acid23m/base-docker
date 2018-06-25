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

# remove certificates
if [[ -f "$PWD/conf/certs/cert.key" ]]; then
    rm "$PWD/conf/certs/cert.key"
fi

if [[ -f "$PWD/conf/certs/cert.crt" ]]; then
    rm "$PWD/conf/certs/cert.crt"
fi

# remove containers
docker-compose down

exit 0
