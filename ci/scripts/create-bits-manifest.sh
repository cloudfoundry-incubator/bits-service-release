#!/bin/bash -e

cd $(dirname $0)/../../

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD

if [ -z "$BLOBSTORE_TYPE" ]
then
  ./scripts/generate-bosh-lite-manifest
else
  ./scripts/generate-bosh-lite-manifest ./spec/assets/body-size-stub.yml ./templates/$BLOBSTORE_TYPE.yml
fi

./scripts/manifest_parser.rb deployments/bits-service-release-bosh-lite.yml > "../manifests/manifest.yml"
