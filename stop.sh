#!/usr/bin/env bash

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
