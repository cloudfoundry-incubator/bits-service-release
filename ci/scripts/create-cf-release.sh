#!/bin/bash -ex

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD
bosh status

cd git-cf-release
./scripts/update
./scripts/generate-bosh-lite-dev-manifest

bosh create release --force --with-tarball
mv dev_releases/cf/cf-*.tgz ../assets/release.tgz

mv bosh-lite/deployments/cf.yml ../assets/manifest.yml
