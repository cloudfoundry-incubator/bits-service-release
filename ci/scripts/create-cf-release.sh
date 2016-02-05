#!/bin/bash -e

cd $(dirname $0)/../../../git-cf-release

./scripts/update

bosh create release --force --name cf --with-tarball
mv dev_releases/cf/cf-*.tgz ../assets/release.tgz
