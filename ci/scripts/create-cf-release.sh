#!/bin/bash -e

cd $(dirname $0)/../../../git-cf-release

version=$(cat $VERSION_FILE)

bosh -n --parallel 10 sync blobs
bosh create release --force --name cf --with-tarball --version $version
mv dev_releases/cf/cf-*.tgz ../releases/
