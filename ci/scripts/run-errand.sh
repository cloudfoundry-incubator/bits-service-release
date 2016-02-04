#!/bin/bash -ex

bosh -u x -p x target $BOSH_TARGET Lite
bosh login $BOSH_USERNAME $BOSH_PASSWORD
bosh status

bosh download manifest cf-warden > manifest.yml
bosh deployment manifest.yml

bosh run errand $ERRAND_NAME
