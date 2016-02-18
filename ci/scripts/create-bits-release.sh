#!/bin/bash -e

cd $(dirname $0)/../../

version=$(cat $VERSION_FILE)
bosh create release --force --name bits-service --with-tarball --version $version
mv dev_releases/bits-service/bits-service-*.tgz ../releases/
