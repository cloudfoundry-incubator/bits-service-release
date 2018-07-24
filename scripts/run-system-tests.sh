#!/bin/bash

: ${1?"Please provide a blobstore type as argument. USAGE: run-system-tests.sh (local|webdav|s3|...)"}

cd $(dirname $0)/..

if [ "$1" == "webdav" -o "$1" == "local" ]; then
# the tests use bosh ssh for webdav and local
: ${BOSH_ENVIRONMENT?"Please set bosh env variable BOSH_ENVIRONMENT to access the blobstore VM."}
: ${BOSH_CLIENT?"Please set bosh env variable BOSH_CLIENT to access the blobstore VM."}
: ${BOSH_CLIENT_SECRET?"Please set bosh env variable BOSH_CLIENT_SECRET to access the blobstore VM."}
: ${BOSH_DEPLOYMENT?"Please set bosh env variable BOSH_DEPLOYMENT to access the blobstore VM."}
fi

# build bitsgo
pushd src/github.com/petergtz/bitsgo/cmd/bitsgo
    go install
    if [ $? != 0 ]; then
        echo "Error: Could not compile bitsgo"
        exit 1
    fi
popd

# generate config and run bitsgo
if [ "$1" != "local" ]; then
    source .private/$1.sh
fi
pushd scripts/system-test-config
    bosh interpolate --vars-store=var-store.yml generate-cert.yml > /dev/null
    bosh interpolate var-store.yml --path /bits_service_ssl/ca > ca_cert
    bosh interpolate var-store.yml --path /bits_service_ssl/certificate > cert_file
    bosh interpolate var-store.yml --path /bits_service_ssl/private_key > key_file

    BITS_LISTEN_ADDR=127.0.0.1 bitsgo -c <(spruce merge localhost-config.yml $1.yml) &
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
