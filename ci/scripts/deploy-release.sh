#!/bin/bash -e

cd $(dirname $0)/../../

if [ -n "$RELEASE_VERSION_FILE" ]; then
  export RELEASE_VERSION=`cat $RELEASE_VERSION_FILE`
fi

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD

bosh deployment $MANIFEST_PATH
bosh -n deploy
