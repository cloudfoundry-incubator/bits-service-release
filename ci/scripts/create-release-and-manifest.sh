#!/bin/bash -ex

cd git-bits-service-release

apt-get install wget
wget https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.7/spiff_linux_amd64.zip
unzip spiff_linux_amd64.zip
mv spiff /usr/local/bin/

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
