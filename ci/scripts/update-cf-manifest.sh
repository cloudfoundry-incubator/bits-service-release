#!/bin/bash -e

cd $(dirname $0)/../../

spruce merge ./ci/manifests/cf.yml ./ci/manifests/tweaks.yml ${MANIFEST_STUBS} > ../manifests/manifest.yml
