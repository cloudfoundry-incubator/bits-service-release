#!/bin/bash -ex

cd git-bits-service-release

bundle install
bundle exec rspec spec
