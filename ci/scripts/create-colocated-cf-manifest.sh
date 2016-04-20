#!/bin/bash -e

cd $(dirname $0)/../../

spiff merge ./ci/manifests/cf-with-flag.yml ./templates/local.yml > ../manifests/manifest-$(cat $VERSION_FILE).yml
