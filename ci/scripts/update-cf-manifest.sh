#!/bin/bash -e

cd $(dirname $0)/../../

spruce merge ./ci/manifest/cf.yml ./ci/manifest/tweaks.yml ${MANIFEST_STUBS} > ../manifests/manifest.yml
