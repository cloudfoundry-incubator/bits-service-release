#!/bin/bash -ex

GOOS=linux GOARCH=amd64 go build -o bitsgo github.com/cloudfoundry-incubator/bits-service/cmd/bitsgo

docker build . -t "flintstonecf/bits-service:2.24.0"
