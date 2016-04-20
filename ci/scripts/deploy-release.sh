#!/bin/bash -e

cd $(dirname $0)/../../

if [ -n "$RELEASE_VERSION_FILE" ]; then
  if [ -e "$RELEASE_VERSION_FILE" ]; then
    export RELEASE_VERSION=`cat $RELEASE_VERSION_FILE`
    echo "Using RELEASE_VERSION=\"$RELEASE_VERSION\""
  else
    echo "The \$RELEASE_VERSION_FILE \"$RELEASE_VERSION_FILE\" does not exist"
    exit 1
  fi
fi

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD

bosh deployment $MANIFEST_PATH
bosh -n deploy
