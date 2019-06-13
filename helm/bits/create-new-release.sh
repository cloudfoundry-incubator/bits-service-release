#!/bin/bash -ex

cd $(dirname $0)/..

helm package bits
helm repo index . --url http://cloudfoundry-incubator.github.io/bits-service-release/helm
helm repo add bits http://cloudfoundry-incubator.github.io/bits-service-release/helm
helm repo list
