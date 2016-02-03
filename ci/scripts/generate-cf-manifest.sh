#!/bin/bash -ex

apt-get install wget
wget https://github.com/cloudfoundry-incubator/spiff/releases/download/v1.0.7/spiff_linux_amd64.zip
unzip spiff_linux_amd64.zip
mv spiff /usr/local/bin/

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD
bosh status

cd git-cf-release
./scripts/generate-bosh-lite-dev-manifest

mv bosh-lite/deployments/cf.yml ../assets/manifest.yml
