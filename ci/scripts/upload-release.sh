#!/bin/bash -e

cd $(dirname $0)/../../

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD

bosh upload release $RELEASE_FILE --skip-if-exists
