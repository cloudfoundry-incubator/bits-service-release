#!/bin/bash -e

cd $(dirname $0)/../../

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD

if [ -z "$BLOBSTORE_TYPE" ]
then
  ./scripts/generate-bosh-lite-manifest ./templates/$BLOBSTORE_TYPE-blobstore-test.yml
else
  ./scripts/generate-bosh-lite-manifest
fi

./scripts/manifest_parser.rb deployments/bits-service-release-bosh-lite.yml > "../manifests/manifest.yml"
