#!/bin/bash -x

get-bits-cert(){
    kubectl get secret bits-cert \
      --output go-template \
      --template '{{(index .data "cert_file")}}'
}

copy-cert() {
    local bits_cert_dir="/workspace/docker/certs.d/$BITS_REGISTRY/"
    mkdir --parents "$bits_cert_dir"
    get-bits-cert | base64 -d > "$bits_cert_dir/ca.crt"

    echo "Sucessfully copied certs"
}

if get-bits-cert; then
    copy-cert
else
    echo "Cert not found"
    exit 1
fi
