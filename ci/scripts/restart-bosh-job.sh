#!/bin/bash -e

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD

bosh deployment $MANIFEST_PATH
bosh -n stop --soft --force --skip-drain $JOB_NAME
bosh -n start --force $JOB_NAME
