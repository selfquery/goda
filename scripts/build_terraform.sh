#!/bin/sh

until $(curl --output /dev/null --silent --head --fail http://localstack:4572); do
    echo 'waiting for localstack ...'
    sleep 5
done

# terraform apply
sleep 5
terraform apply -auto-approve

# run testing
echo 'run tests'