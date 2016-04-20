#!/bin/bash -e

cd $(dirname $0)/../../

if [ -e "$VERSION_FILE" ]; then
  export VERSION=$(cat $VERSION_FILE)
  echo "Using VERSION=\"$VERSION\""
else
  echo "The \$VERSION_FILE \"$VERSION_FILE\" does not exist"
  exit 1
fi

spiff merge ./ci/manifests/cf-with-flag.yml ./templates/local.yml > "../manifests/manifest-$VERSION.yml"
