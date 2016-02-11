#!/bin/bash -e

cd $(dirname $0)/../../

bundle install
bundle exec rspec spec
