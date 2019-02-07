#!/bin/bash -e

: ${1?"Please provide a blobstore type as argument. USAGE: run-system-tests.sh (local|webdav|s3|...)"}

cd $(dirname $0)/..

cleanup () {
    pushd scripts/system-test-config
        kill -9 $BITSGO_PID || true
        rm -rf cert_file key_file ca_cert var-store.yml manifest.yml blobstore.crt blobstore.key ca.crt
    popd
}
trap cleanup EXIT

# build bitsgo
pushd src/github.com/cloudfoundry-incubator/bits-service/cmd/bitsgo
    go install
    if [ $? != 0 ]; then
        echo "Error: Could not compile bitsgo"
        exit 1
    fi
popd

if [ "$1" == "webdav" ]; then
    mkdir -p /tmp/blobstore_url_signer/src/github.com/cloudfoundry
    export GOPATH=/tmp/blobstore_url_signer
    pushd /tmp/blobstore_url_signer/src/github.com/cloudfoundry
        rm -rf blobstore_url_signer
        git clone https://github.com/cloudfoundry/blobstore_url_signer.git
        sleep 1
        pushd blobstore_url_signer
            go build
        popd
    popd
    if pgrep blobstore_url_signer; then pkill blobstore_url_signer; fi
    mkdir -p /tmp/blobstore_url_signer
    /tmp/blobstore_url_signer/src/github.com/cloudfoundry/blobstore_url_signer/blobstore_url_signer \
        -secret BLOBSTORE_SECURE_LINK_SECRET -network unix -laddr /tmp/blobstore_url_signer/signer.sock &

    pushd scripts/system-test-config
        rm -f var-store.yml
        bosh interpolate --vars-store=var-store.yml generate-cert.yml
        bosh interpolate var-store.yml --path /blobstore_ssl/ca > ca.crt
        bosh interpolate var-store.yml --path /blobstore_ssl/certificate > blobstore.crt
        bosh interpolate var-store.yml --path /blobstore_ssl/private_key > blobstore.key
    popd
    # For this to work on MacOS, make sure you have:
    # brew tap denji/nginx
    # brew install nginx-full --with-webdav --with-dav-ext-module --with-secure-link
    if pgrep nginx; then pkill nginx; fi
    nginx -c $PWD/scripts/nginx.conf &
fi

# generate config and run bitsgo
if [ "$1" != "local" &&  "$1" != "webdav" && ]; then
    source .private/$1.sh
fi
pushd scripts/system-test-config
    bosh interpolate --vars-store=var-store.yml generate-cert.yml > /dev/null
    bosh interpolate var-store.yml --path /bits_service_ssl/ca > ca_cert
    bosh interpolate var-store.yml --path /bits_service_ssl/certificate > cert_file
    bosh interpolate var-store.yml --path /bits_service_ssl/private_key > key_file

    BITS_LISTEN_ADDR=127.0.0.1 bitsgo -c <(spruce merge localhost-config.yml $1.yml) &
    BITSGO_PID=$!
    sleep 2
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
