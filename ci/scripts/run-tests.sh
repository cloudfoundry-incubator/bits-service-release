#!/bin/bash -ex

cd $(dirname $0)/../../

bundle install
bundle exec rspec spec
