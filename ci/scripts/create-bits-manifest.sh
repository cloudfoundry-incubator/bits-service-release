#!/bin/bash -e

cd $(dirname $0)/../../

if [ -e "$VERSION_FILE" ]; then
  export VERSION=$(cat $VERSION_FILE)
  echo "Using VERSION=\"$VERSION\""
else
  echo "The \$VERSION_FILE \"$VERSION_FILE\" does not exist"
  exit 1
fi

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD

if [ -z "$BLOBSTORE_TYPE" ]
then
  ./scripts/generate-default-bosh-lite-manifest
else
  ./scripts/generate-test-bosh-lite-manifest ./templates/$BLOBSTORE_TYPE.yml
fi

cp deployments/bits-service-release.yml ../manifests/manifest-$VERSION.yml
