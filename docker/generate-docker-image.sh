#!/bin/bash -ex

CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o bitsgo github.com/cloudfoundry-incubator/bits-service/cmd/bitsgo

docker build . -t "flintstonecf/bits-service"
