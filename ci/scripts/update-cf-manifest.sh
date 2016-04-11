#!/bin/bash -e

cd $(dirname $0)/../../

set -x
echo MANIFEST_STUBS: ${MANIFEST_STUBS}
find .

spruce merge ./ci/manifests/cf.yml ./ci/manifests/tweaks.yml ${MANIFEST_STUBS} > ../manifests/manifest.yml
