#!/bin/sh
# http://localhost:4566/health?reload

until $(curl --output /dev/null --silent --head --fail http://localstack:4572); do
    echo 'waiting for localstack ...'
    sleep 5
done

terraform apply -auto-approve