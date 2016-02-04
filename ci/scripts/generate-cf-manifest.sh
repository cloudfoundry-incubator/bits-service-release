#!/bin/bash -ex

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD
bosh status

cd git-cf-release
./scripts/generate-bosh-lite-dev-manifest

mv bosh-lite/deployments/cf.yml ../assets/manifest.yml
