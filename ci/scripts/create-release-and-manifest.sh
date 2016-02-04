#!/bin/bash -ex

cd git-bits-service-release

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD
bosh status

bosh -n delete deployment bits-service
set +e
bosh -n delete release bits-service
set -e

./scripts/generate-bosh-lite-manifest
rm -rf ../assets/*

mv deployments/bits-service-release-bosh-lite.yml ../assets/manifest.yml
cat ../assets/manifest.yml

rm -rf dev_releases
bosh create release --force --name bits-service --with-tarball
mv dev_releases/bits-service/bits-service-*.tgz ../assets/
