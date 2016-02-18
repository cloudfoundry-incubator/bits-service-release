#!/bin/bash -e

cd $(dirname $0)/../../

version=$(cat $VERSION_FILE)
bosh create release --force --name $RELEASE_NAME --with-tarball --version $version
mv dev_releases/$RELEASE_NAME/$RELEASE_NAME-*.tgz ../releases/
