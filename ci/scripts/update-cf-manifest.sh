#!/bin/bash -e

cd $(dirname $0)/../../

if [ -e "$VERSION_FILE" ]; then
  export VERSION=$(cat $VERSION_FILE)
  echo "Using VERSION=\"$VERSION\""
else
  echo "The \$VERSION_FILE \"$VERSION_FILE\" does not exist"
  exit 1
fi

spruce merge ./ci/manifests/cf-${IAAS}.yml ./ci/manifests/tweaks.yml ${MANIFEST_STUBS} > ../manifests/manifest-${VERSION}.yml
