#!/bin/bash

cd $(dirname $0)/..

# build bitsgo
pushd src/github.com/petergtz/bitsgo/cmd/bitsgo
    go install
popd

# generate config and run bitsgo
source .private/$1.sh
pushd scripts/system-test-config
    bosh interpolate --vars-store=var-store.yml generate-cert.yml > /dev/null
    bosh interpolate var-store.yml --path /bits_service_ssl/ca > ca_cert
    bosh interpolate var-store.yml --path /bits_service_ssl/certificate > cert_file
    bosh interpolate var-store.yml --path /bits_service_ssl/private_key > key_file

    bitsgo -c <(spruce merge localhost-config.yml $1.yml) &
    BITSGO_PID=$!
    sleep 1
popd

# generate config for tests
spruce merge \
    scripts/system-test-config/localhost-manifest.yml \
    scripts/system-test-config/$1.yml \
    > scripts/system-test-config/manifest.yml

# run tests
BITS_SERVICE_PRIVATE_ENDPOINT_IP=127.0.0.1 \
    BITS_SERVICE_MANIFEST=scripts/system-test-config/manifest.yml \
    BITS_SERVICE_CA_CERT=scripts/system-test-config/ca_cert \
    \
    bundle exec rspec $2

# Cleanup
pushd scripts/system-test-config
    kill -9 $BITSGO_PID
    rm -rf cert_file key_file ca_cert var-store.yml manifest.yml
popd