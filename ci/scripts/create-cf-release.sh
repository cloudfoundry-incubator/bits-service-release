#!/bin/bash -e

cd $(dirname $0)/../../../git-cf-release

version=$(cat $VERSION_FILE)

bosh create release --force --name cf --with-tarball --version $version
mv dev_releases/cf/cf-*.tgz ../releases/release.tgz
